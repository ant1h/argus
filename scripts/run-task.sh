#!/usr/bin/env bash
set -euo pipefail

# Argus task runner
# Usage: run-task.sh <project-id> <task-id>

ARGUS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ID="${1:?Usage: run-task.sh <project-id> <task-id>}"
TASK_ID="${2:?Usage: run-task.sh <project-id> <task-id>}"

PROJECT_DIR="$ARGUS_DIR/projects/$PROJECT_ID"
PROJECT_FILE="$PROJECT_DIR/project.md"
LOG_DIR="$PROJECT_DIR/logs/$TASK_ID"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M)"
LOG_FILE="$LOG_DIR/$TIMESTAMP.md"

# Validate project exists
if [[ ! -f "$PROJECT_FILE" ]]; then
    echo "ERROR: Project file not found: $PROJECT_FILE" >&2
    exit 1
fi

# Extract repo URL from project.md frontmatter
REPO_URL="$(sed -n '/^---$/,/^---$/p' "$PROJECT_FILE" | grep '^repo:' | sed 's/repo: *//')"
if [[ -z "$REPO_URL" ]]; then
    echo "ERROR: No repo URL found in $PROJECT_FILE" >&2
    exit 1
fi

# Extract task block from project.md
TASK_BLOCK="$(awk "
    /^### ${TASK_ID}\$/ { found=1; next }
    found && /^###? / { found=0; next }
    found { print }
" "$PROJECT_FILE")"
if [[ -z "$TASK_BLOCK" ]]; then
    echo "ERROR: Task '$TASK_ID' not found in $PROJECT_FILE" >&2
    exit 1
fi

# Parse task fields
TASK_TYPE="$(echo "$TASK_BLOCK" | grep '\*\*type:\*\*' | sed 's/.*\*\* //')"
TASK_OBJECTIVE="$(echo "$TASK_BLOCK" | grep '\*\*objective:\*\*' | sed 's/.*\*\* //')"
TASK_SUBPROJECT="$(echo "$TASK_BLOCK" | grep '\*\*subproject:\*\*' | sed 's/.*\*\* //' || echo "")"

# Parse resources
TASK_RESOURCES="$(echo "$TASK_BLOCK" | awk '/\*\*resources:\*\*$/,/\*\*[^r]|^###|^##/' | grep -E '(url|note|local|gcs):' || echo "")"

# Derive local repo path from URL (assumes ~/Projects/perso/<repo-name>)
REPO_NAME="$(basename "$REPO_URL" .git)"
REPO_LOCAL="$HOME/Projects/perso/$REPO_NAME"

# Clone if not present locally
if [[ ! -d "$REPO_LOCAL" ]]; then
    echo "Cloning $REPO_URL to $REPO_LOCAL..."
    git clone "$REPO_URL" "$REPO_LOCAL"
fi

# Build the prompt for Claude Code
PROMPT="You are Argus, an autonomous agent working on project '$PROJECT_ID', task '$TASK_ID'.

## Task
- **Type:** $TASK_TYPE
- **Objective:** $TASK_OBJECTIVE

## Resources
$TASK_RESOURCES
"

# Add type-specific instructions
if [[ "$TASK_TYPE" == "roadmap" ]]; then
    ROADMAP_FILE="ROADMAP.md"
    if [[ -n "$TASK_SUBPROJECT" ]]; then
        ROADMAP_FILE="roadmaps/$TASK_SUBPROJECT.md"
    fi
    PROMPT+="
## Roadmap instructions
1. Read $ROADMAP_FILE in this repo
2. Find the highest priority item with status 'todo' that has no unmet dependencies and is assigned to 'agent' or 'both'
3. Implement it
4. Update the item's status to 'done' (if fully complete and tests pass) or 'review' (if it needs Antoine's review)
5. Commit your changes with a clear message
6. Report what you did
"
elif [[ "$TASK_TYPE" == "routine" ]]; then
    PROMPT+="
## Routine instructions
Execute the objective described above. Be concise in your output.
Commit any changes if applicable.
Report what you did and the outcome.
"
fi

PROMPT+="
## Rules
- If the task is clear and validation is straightforward, complete it fully
- If the result is ambiguous or risky, stop and note that this needs Antoine's review
- Always report: what you did, outcome (success/failed/needs_review), any artifacts (commits, PRs)
"

# Create log directory
mkdir -p "$LOG_DIR"

# Run Claude Code
echo "[$TIMESTAMP] Running task '$TASK_ID' for project '$PROJECT_ID'..."
echo "Working directory: $REPO_LOCAL"

CLAUDE_OUTPUT=""
RUN_STATUS="success"

CLAUDE_OUTPUT=$(cd "$REPO_LOCAL" && claude --print --dangerously-skip-permissions -p "$PROMPT" 2>&1) || RUN_STATUS="failed"

# Write log
cat > "$LOG_FILE" << EOF
---
task: $TASK_ID
project: $PROJECT_ID
timestamp: $(date -Iseconds)
status: $RUN_STATUS
---

## Prompt
$TASK_OBJECTIVE

## Output
$CLAUDE_OUTPUT
EOF

# Check if output indicates needs_review
if echo "$CLAUDE_OUTPUT" | grep -qi "needs.*review\|needs antoine\|requires review"; then
    sed -i "s/^status: .*/status: needs_review/" "$LOG_FILE"
    RUN_STATUS="needs_review"
fi

echo "[$TIMESTAMP] Task '$TASK_ID' completed with status: $RUN_STATUS"
echo "Log written to: $LOG_FILE"

# Update STATUS.md
"$ARGUS_DIR/scripts/update-status.sh"
