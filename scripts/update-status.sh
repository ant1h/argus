#!/usr/bin/env bash
set -euo pipefail

# Regenerates STATUS.md from all project logs

ARGUS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_FILE="$ARGUS_DIR/STATUS.md"

cat > "$STATUS_FILE" << 'HEADER'
# Argus Status

> Auto-generated. Do not edit manually.

| Project | Task | Last Run | Status | Pushed | Next Run |
|---------|------|----------|--------|--------|----------|
HEADER

# Iterate over all projects
for project_dir in "$ARGUS_DIR"/projects/*/; do
    [[ -d "$project_dir" ]] || continue
    project_id="$(basename "$project_dir")"
    [[ "$project_id" == ".template" ]] && continue

    project_file="$project_dir/project.md"
    [[ -f "$project_file" ]] || continue

    # Find all tasks defined in project.md
    while IFS= read -r task_id; do
        [[ -z "$task_id" ]] && continue

        # Get schedule
        schedule="$(awk "
            /^### ${task_id}\$/ { found=1; next }
            found && /^###? / { found=0; next }
            found { print }
        " "$project_file" | grep '\*\*schedule:\*\*' | sed 's/.*\*\* //' || echo "manual")"

        # Find latest log
        log_dir="$project_dir/logs/$task_id"
        last_run="never"
        status="-"
        pushed="-"

        if [[ -d "$log_dir" ]]; then
            latest_log="$(ls -1 "$log_dir"/*.md 2>/dev/null | sort | tail -1 || echo "")"
            if [[ -n "$latest_log" ]]; then
                last_run="$(basename "$latest_log" .md | tr '_' ' ')"
                status="$(sed -n '/^---$/,/^---$/p' "$latest_log" | grep '^status:' | sed 's/status: *//')"
                pushed="$(sed -n '/^---$/,/^---$/p' "$latest_log" | grep '^pushed:' | sed 's/pushed: *//' || echo "-")"
            fi
        fi

        # Calculate next run from cron expression (approximate)
        next_run="$schedule"

        echo "| $project_id | $task_id | $last_run | $status | $pushed | $next_run |" >> "$STATUS_FILE"

    done < <(grep '^### ' "$project_file" | sed 's/^### //')
done

echo "" >> "$STATUS_FILE"
echo "*Last updated: $(date -Iseconds)*" >> "$STATUS_FILE"

echo "STATUS.md updated."
