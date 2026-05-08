#!/bin/bash
# Usage: ./onboard.sh <username> <email>

set -e

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

BASE_URL="http://localhost:3000"

ADMIN_TOKEN="fa67c9b47909a0f015c47be48224845477186f6e"

BASE_OWNER="10x"
BASE_REPO="test"

# --------------------------------------------------
# INPUT
# --------------------------------------------------

USERNAME=$1
EMAIL=$2
PASSWORD=$(openssl rand -base64 12)

if [ "$#" -ne 2 ]; then
  echo "Usage: ./onboard.sh <username> <email>"
  exit 1
fi

echo "=========================================="
echo "Onboarding: $USERNAME"
echo "=========================================="

# --------------------------------------------------
# HELPERS
# --------------------------------------------------

admin_api() {
  local method=$1
  local path=$2
  local data=$3

  if [ -n "$data" ]; then
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -H "Authorization: token $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -H "Authorization: token $ADMIN_TOKEN"
  fi
}

user_api() {
  local method=$1
  local path=$2
  local data=$3

  if [ -n "$data" ]; then
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -u "$USERNAME:$PASSWORD" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -u "$USERNAME:$PASSWORD"
  fi
}

# --------------------------------------------------
# 1. CREATE USER
# --------------------------------------------------

echo "Creating user..."

admin_api POST "/admin/users" \
"{
  \"username\": \"$USERNAME\",
  \"email\": \"$EMAIL\",
  \"password\": \"$PASSWORD\",
  \"must_change_password\": false
}" > /dev/null

echo "✓ User created"

sleep 2

# --------------------------------------------------
# 2. GRANT ACCESS TO BASE REPO
# --------------------------------------------------

echo "Granting read access..."

admin_api PUT "/repos/$BASE_OWNER/$BASE_REPO/collaborators/$USERNAME" \
'{"permission":"read"}' > /dev/null

echo "✓ Access granted"

sleep 2

# --------------------------------------------------
# 3. FORK REPO
# --------------------------------------------------

echo "Forking repository..."

FORK_RESPONSE=$(user_api POST \
  "/repos/$BASE_OWNER/$BASE_REPO/forks" \
  '{}')

if echo "$FORK_RESPONSE" | grep -q "error"; then
  echo "Fork failed:"
  echo "$FORK_RESPONSE"

  exit 1
fi

echo "✓ Repository forked"

# --------------------------------------------------
# 4. WAIT FOR FORK
# --------------------------------------------------

echo "Waiting for fork..."

MAX_RETRIES=30
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do

  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $ADMIN_TOKEN" \
    "$BASE_URL/api/v1/repos/$USERNAME/$BASE_REPO")

  if [ "$STATUS" == "200" ]; then
    break
  fi

  sleep 2
  COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
  echo "Fork timeout"
  exit 1
fi

echo "✓ Fork available"

# --------------------------------------------------
# 5. ENABLE ISSUES + PROJECTS
# --------------------------------------------------

echo "Enabling repo features..."

admin_api PATCH "/repos/$USERNAME/$BASE_REPO" \
'{
  "has_issues": true,
  "has_projects": true
}' > /dev/null

echo "✓ Issues/projects enabled"

# --------------------------------------------------
# 6. CREATE ISSUES
# --------------------------------------------------

echo "Creating issues..."

declare -A ISSUE_BODIES

ISSUE_BODIES["Sub-Module 3"]="Body for SM3"
ISSUE_BODIES["Sub-Module 4"]="Body for SM4"
ISSUE_BODIES["Sub-Module 5"]="Body for SM5"

MODULES=(
  "Sub-Module 3"
  "Sub-Module 4"
  "Sub-Module 5"
)

ISSUE_IDS=()

for title in "${MODULES[@]}"; do

  BODY="${ISSUE_BODIES[$title]}"

  RESPONSE=$(admin_api POST \
    "/repos/$USERNAME/$BASE_REPO/issues" \
    "$(jq -n \
      --arg t "$title" \
      --arg b "$BODY" \
      '{title:$t, body:$b}')")

  ISSUE_ID=$(echo "$RESPONSE" | jq -r '.id')

  ISSUE_IDS+=("$ISSUE_ID")

  echo "  ✓ Created issue id=$ISSUE_ID"
done

# --------------------------------------------------
# 7. CREATE PROJECT
# --------------------------------------------------

echo "Creating project board..."

PROJECT=$(admin_api POST \
  "/repos/$USERNAME/$BASE_REPO/projects" \
  '{"title":"Project Board","template_type":"none"}')

PROJECT_ID=$(echo "$PROJECT" | jq -r '.id')

echo "✓ Project id=$PROJECT_ID"

# --------------------------------------------------
# 8. CREATE COLUMNS
# --------------------------------------------------

echo "Creating columns..."

LABS_COL=$(admin_api POST \
  "/repos/$USERNAME/$BASE_REPO/projects/$PROJECT_ID/columns" \
  '{"title":"Labs"}')

LABS_COL_ID=$(echo "$LABS_COL" | jq -r '.id')

DONE_COL=$(admin_api POST \
  "/repos/$USERNAME/$BASE_REPO/projects/$PROJECT_ID/columns" \
  '{"title":"Done"}')

DONE_COL_ID=$(echo "$DONE_COL" | jq -r '.id')

echo "✓ Columns created"

# --------------------------------------------------
# 9. ASSIGN ISSUES TO COLUMN
# --------------------------------------------------

echo "Assigning issues to Labs..."

for id in "${ISSUE_IDS[@]}"; do

  admin_api POST \
    "/repos/$USERNAME/$BASE_REPO/projects/$PROJECT_ID/columns/$LABS_COL_ID/issues/$id" \
    "" > /dev/null

  echo "  ✓ Issue $id -> Labs"
done

# --------------------------------------------------
# DONE
# --------------------------------------------------

echo ""
echo "=========================================="
echo "DONE"
echo "=========================================="

echo "Username: $USERNAME"
echo "Password: $PASSWORD"

echo ""
echo "Fork:"
echo "$BASE_URL/$USERNAME/$BASE_REPO"

echo ""
echo "Project:"
echo "$BASE_URL/$USERNAME/$BASE_REPO/projects/$PROJECT_ID"