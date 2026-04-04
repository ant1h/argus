#!/usr/bin/env bash
set -euo pipefail

# Argus task runner
# Usage: run-task.sh <project-id> <task-id>
#
# Flow:
#   1. Clone/pull repo
#   2. Run task (Claude does the work, may commit)
#   3. If commits were made, run review skill (separate Claude invocation)
#   4. Push or hold based on review decision
#   5. Write log, update STATUS.md

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

# Agent working copy lives inside argus/repos/<project-id>
REPO_LOCAL="$ARGUS_DIR/repos/$PROJECT_ID"

# Clone if not present, pull if already cloned
if [[ ! -d "$REPO_LOCAL" ]]; then
    echo "Cloning $REPO_URL to $REPO_LOCAL..."
    mkdir -p "$ARGUS_DIR/repos"
    git clone "$REPO_URL" "$REPO_LOCAL"
else
    echo "Pulling latest changes..."
    git -C "$REPO_LOCAL" pull --ff-only 2>&1 || echo "WARNING: pull failed, running on current state"
fi

# Record HEAD before task runs
HEAD_BEFORE="$(git -C "$REPO_LOCAL" rev-parse HEAD)"

# ── Step 1: Build task prompt ──

TASK_PROMPT="You are Argus, an autonomous agent working on project '$PROJECT_ID', task '$TASK_ID'.

## Task
- **Type:** $TASK_TYPE
- **Objective:** $TASK_OBJECTIVE

## Resources
$TASK_RESOURCES
"

if [[ "$TASK_TYPE" == "roadmap" ]]; then
    ROADMAP_FILE="ROADMAP.md"
    if [[ -n "$TASK_SUBPROJECT" ]]; then
        ROADMAP_FILE="roadmaps/$TASK_SUBPROJECT.md"
    fi
    TASK_PROMPT+="
## Roadmap instructions
1. Read $ROADMAP_FILE in this repo
2. Find the highest priority item with status 'todo' that has no unmet dependencies and is assigned to 'agent' or 'both'
3. Implement it
4. Update the item's status to 'done' (if fully complete and tests pass) or 'review' (if it needs Antoine's review)
5. Commit your changes with a clear message
6. Do NOT push — a separate review step will handle that
7. Report what you did
"
elif [[ "$TASK_TYPE" == "routine" ]]; then
    TASK_PROMPT+="
## Routine instructions
Execute the objective described above. Be concise in your output.
Commit any changes if applicable. Do NOT push — a separate review step will handle that.
Report what you did and the outcome.
"
fi

TASK_PROMPT+="
## Rules
- Always report: what you did, outcome (success/failed/needs_review), any artifacts (commits)
- Do NOT push to remote. Commits only.
"

# Create log directory
mkdir -p "$LOG_DIR"

# ── Step 2: Run task ──

echo "[$TIMESTAMP] Running task '$TASK_ID' for project '$PROJECT_ID'..."
echo "Working directory: $REPO_LOCAL"

TASK_OUTPUT=""
RUN_STATUS="success"

TASK_OUTPUT=$(cd "$REPO_LOCAL" && claude --print --dangerously-skip-permissions -p "$TASK_PROMPT" 2>&1) || RUN_STATUS="failed"

# ── Step 3: Review & push decision ──

HEAD_AFTER="$(git -C "$REPO_LOCAL" rev-parse HEAD)"
REVIEW_OUTPUT=""
PUSH_DECISION="none"

if [[ "$HEAD_BEFORE" != "$HEAD_AFTER" && "$RUN_STATUS" != "failed" ]]; then
    echo "[$TIMESTAMP] Changes detected. Running review..."

    # Gather diff and commit info
    DIFF="$(git -C "$REPO_LOCAL" diff "$HEAD_BEFORE".."$HEAD_AFTER")"
    COMMITS="$(git -C "$REPO_LOCAL" log --oneline "$HEAD_BEFORE".."$HEAD_AFTER")"
    DIFF_STAT="$(git -C "$REPO_LOCAL" diff --stat "$HEAD_BEFORE".."$HEAD_AFTER")"

    # Load review skill
    REVIEW_SKILL="$(cat "$ARGUS_DIR/skills/review-push.md")"

    REVIEW_PROMPT="$REVIEW_SKILL

## Context
- **Project:** $PROJECT_ID
- **Task:** $TASK_ID ($TASK_TYPE)
- **Objective:** $TASK_OBJECTIVE

## Commits
$COMMITS

## Diff stats
$DIFF_STAT

## Full diff
\`\`\`diff
$DIFF
\`\`\`"

    REVIEW_OUTPUT=$(cd "$REPO_LOCAL" && claude --print --dangerously-skip-permissions -p "$REVIEW_PROMPT" 2>&1) || true

    # Parse decision
    if echo "$REVIEW_OUTPUT" | grep -q "DECISION=push"; then
        PUSH_DECISION="push"
        echo "[$TIMESTAMP] Review decision: PUSH"
        git -C "$REPO_LOCAL" push 2>&1 || { PUSH_DECISION="push_failed"; echo "WARNING: push failed"; }
    else
        PUSH_DECISION="hold"
        echo "[$TIMESTAMP] Review decision: HOLD for Antoine's review"
        RUN_STATUS="needs_review"
    fi
else
    echo "[$TIMESTAMP] No new commits."
fi

# ── Step 4: Write log ──

cat > "$LOG_FILE" << EOF
---
task: $TASK_ID
project: $PROJECT_ID
timestamp: $(date -Iseconds)
status: $RUN_STATUS
pushed: $PUSH_DECISION
commits: $HEAD_BEFORE..$HEAD_AFTER
---

## Objective
$TASK_OBJECTIVE

## Task output
$TASK_OUTPUT

## Review
$REVIEW_OUTPUT
EOF

# Check if task output indicates needs_review (even without commits)
if [[ "$PUSH_DECISION" == "none" ]] && echo "$TASK_OUTPUT" | grep -qi "needs.*review\|needs antoine\|requires review"; then
    sed -i "s/^status: .*/status: needs_review/" "$LOG_FILE"
    RUN_STATUS="needs_review"
fi

echo "[$TIMESTAMP] Task '$TASK_ID' completed with status: $RUN_STATUS (push: $PUSH_DECISION)"
echo "Log written to: $LOG_FILE"

# ── Step 5: Update dashboard ──

"$ARGUS_DIR/scripts/update-status.sh"
