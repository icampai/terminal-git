#!/bin/bash
# Usage: ./fork.sh <username> <email>
# https://gitea.com/api/swagger#/admin, https://docs.gitea.com/api
# https://github.com/go-gitea/gitea/pull/36008, https://github.com/go-gitea/gitea/issues/36824, https://github.com/go-gitea/gitea/pull/36831
# https://github.com/hanism01/gitea/tree/fix/project-board-api-review-feedback 
set -e

BASE_URL="http://localhost:3000"
OWNER="10x"
REPO="test"
TOKEN="fa67c9b47909a0f015c47be48224845477186f6e"

if [ -z "$TOKEN" ]; then
  echo "Error: GITEA_TOKEN is not set"
  exit 1
fi

api() {
  local method=$1 path=$2 data=$3
  if [ -n "$data" ]; then
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -H "Authorization: token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$BASE_URL/api/v1$path" \
      -H "Authorization: token $TOKEN"
  fi
}

# ---------- 1. Create Issues ----------
echo "Creating issues..."

declare -A ISSUE_BODIES

ISSUE_BODIES["Sub-Module 3: Shell, Terminal & Filesystem Navigation"]="## sm-3: Shell, Terminal & Filesystem Navigation

- [ ] [Lab 1 — Navigating the Filesystem](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-3/lab-1-exp.md)
- [ ] [Lab 2 — Working with Files & Directories](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-3/lab-2-exp.md)
- [ ] [Lab 3 — Terminal Shortcuts & Efficiency](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-3/lab-3-exp.md)"

ISSUE_BODIES["Sub-Module 4: Filesystem Operations & Content Management"]="## sm-4: Filesystem Operations & Content Management

- [ ] [Lab 1 — File Operations Fundamentals](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-4/lab-1-exp.md)
- [ ] [Lab 2 — File Content Inspection & Management](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-4/lab-2-exp.md)
- [ ] [Lab 3 — Globbing Patterns](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-4/lab-3-exp.md)
- [ ] [Lab 4 — File Timestamps & Content Analysis](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-4/lab-4-exp.md)"

ISSUE_BODIES["Sub-Module 5: Linux System Administration & Discovery"]="## sm-5: Linux System Administration & Discovery

- [ ] [Lab 1 — Auditing a New Development Machine](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-5/lab-1-exp.md)
- [ ] [Lab 2 — Shell History Navigation, Privacy & Session Management](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-5/lab-2-exp.md)"

ISSUE_BODIES["Sub-Module 6: Linux Permissions & Links"]="## sm-6: Linux Permissions & Links

- [ ] [Lab 1 — Inodes, Symbolic Links & Hard Links](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-6/lab-1-exp.md)
- [ ] [Lab 2 — File Permissions, chmod & umask](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-6/lab-2-exp.md)
- [ ] [Lab 3 — Permissions in Practice](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-6/lab-3-code.md)"

ISSUE_BODIES["Sub-Module 7: Shell Environment, Editors & Command Processing"]="## sm-7: Shell Environment, Editors & Command Processing

- [ ] [Lab 1 — Shell Variables, Scoping, PATH & Aliases](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-7/lab-1-exp.md)
- [ ] [Lab 2 — The Shell Expansion Pipeline](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-7/lab-2-exp.md)
- [ ] [Lab 3 — Building a Persistent Shell Environment](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-7/lab-3-code.md)"

ISSUE_BODIES["Sub-Module 8: Process Management, Text Processing & Automation"]="## sm-8: Process Management, Text Processing & Automation

- [ ] [Lab 1 — Processes, Signals & I/O Streams](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-8/lab-1-exp.md)
- [ ] [Lab 2 — Filter Commands & Pipeline Building](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-8/lab-2-exp.md)
- [ ] [Lab 3 — Log & Data Processing Pipelines](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-8/lab-3-code.md)
- [ ] [Lab 4 — Scheduling with Cron](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-8/lab-4-exp.md)"

ISSUE_BODIES["Sub-Module 9: Linux Networking for Web Developers"]="## sm-9: Linux Networking for Web Developers

- [ ] [Lab 1 — Network Configuration Experiments](https://git.icamp.tech/10x/fullstack-web-m0/src/branch/main/M0/sub-mod-9/lab-1-exp.md)"

MILESTONE_NAMES=(
  "Sub-Module 3: Shell, Terminal & Filesystem Navigation"
  "Sub-Module 4: Filesystem Operations & Content Management"
  "Sub-Module 5: Linux System Administration & Discovery"
  "Sub-Module 6: Linux Permissions & Links"
  "Sub-Module 7: Shell Environment, Editors & Command Processing"
  "Sub-Module 8: Process Management, Text Processing & Automation"
  "Sub-Module 9: Linux Networking for Web Developers"
)

ISSUE_IDS=()

for title in "${MILESTONE_NAMES[@]}"; do
  BODY="${ISSUE_BODIES[$title]}"
  RESPONSE=$(api POST "/repos/$OWNER/$REPO/issues" \
    "$(jq -n --arg t "$title" --arg b "$BODY" '{title: $t, body: $b}')")
  ID=$(echo "$RESPONSE" | jq -r '.id')
  ISSUE_IDS+=("$ID")
  echo "  Created issue id=$ID: $title"
done

# ---------- 2. Create Project ----------
echo "Creating project board..."

PROJECT=$(api POST "/repos/$OWNER/$REPO/projects" \
  '{"title": "Project Board", "template_type": "none"}')
PROJECT_ID=$(echo "$PROJECT" | jq -r '.id')
echo "  Project id=$PROJECT_ID"

# ---------- 3. Create Columns ----------
echo "Creating columns..."

LABS_COL=$(api POST "/repos/$OWNER/$REPO/projects/$PROJECT_ID/columns" \
  '{"title": "Labs"}')
LABS_COL_ID=$(echo "$LABS_COL" | jq -r '.id')
echo "  Column 'Labs' id=$LABS_COL_ID"

DONE_COL=$(api POST "/repos/$OWNER/$REPO/projects/$PROJECT_ID/columns" \
  '{"title": "Done"}')
DONE_COL_ID=$(echo "$DONE_COL" | jq -r '.id')
echo "  Column 'Done' id=$DONE_COL_ID"

# ---------- 4. Assign Issues to Labs ----------
echo "Assigning issues to Labs column..."

for id in "${ISSUE_IDS[@]}"; do
  api POST "/repos/$OWNER/$REPO/projects/$PROJECT_ID/columns/$LABS_COL_ID/issues/$id" > /dev/null
  echo "  Issue id=$id -> Labs"
done

echo "Done."