#!/usr/bin/env bash
set -euo pipefail

# Reads all project.md files and installs/updates systemd user timers for each task.
# Usage: install-timers.sh [--dry-run]

ARGUS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN="${1:-}"
TIMER_DIR="$HOME/.config/systemd/user"

mkdir -p "$TIMER_DIR"

# Copy template units if not present
for unit in argus-task@.service argus-task@.timer; do
    if [[ ! -f "$TIMER_DIR/$unit" ]] || ! diff -q "$ARGUS_DIR/automation/systemd/$unit" "$TIMER_DIR/$unit" &>/dev/null; then
        echo "Installing $unit"
        if [[ "$DRY_RUN" != "--dry-run" ]]; then
            cp "$ARGUS_DIR/automation/systemd/$unit" "$TIMER_DIR/$unit"
        fi
    fi
done

# Reload systemd
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    systemctl --user daemon-reload
fi

# Track which timers should exist
declare -A EXPECTED_TIMERS

for project_dir in "$ARGUS_DIR"/projects/*/; do
    [[ -d "$project_dir" ]] || continue
    project_id="$(basename "$project_dir")"
    [[ "$project_id" == ".template" ]] && continue

    project_file="$project_dir/project.md"
    [[ -f "$project_file" ]] || continue

    # Extract tasks and their schedules
    while IFS= read -r task_id; do
        [[ -z "$task_id" ]] && continue

        schedule="$(awk "
            /^### ${task_id}\$/ { found=1; next }
            found && /^###? / { found=0; next }
            found { print }
        " "$project_file" | grep '\*\*schedule:\*\*' | sed 's/.*\*\* //' || echo "")"
        [[ -z "$schedule" ]] && continue

        instance="${project_id}--${task_id}"
        EXPECTED_TIMERS["$instance"]=1

        # Convert cron expression to systemd OnCalendar format
        # Simple conversion: cron "min hour dom mon dow" -> systemd calendar
        read -r cron_min cron_hour cron_dom cron_mon cron_dow <<< "$schedule"

        # Build OnCalendar string
        dow_map=("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
        cal_dow=""
        if [[ "$cron_dow" != "*" ]]; then
            # Convert 1-5 to Mon..Fri etc
            cal_dow=""
            IFS=',' read -ra parts <<< "$(echo "$cron_dow" | sed 's/-/../g')"
            for part in "${parts[@]}"; do
                if [[ "$part" == *".."* ]]; then
                    start="${part%%.*}"
                    end="${part##*.}"
                    cal_dow+="${dow_map[$start]}..${dow_map[$end]},"
                else
                    cal_dow+="${dow_map[$part]},"
                fi
            done
            cal_dow="${cal_dow%,}"
        fi

        cal_month="*"
        [[ "$cron_mon" != "*" ]] && cal_month="$cron_mon"

        cal_day="*"
        [[ "$cron_dom" != "*" ]] && cal_day="$cron_dom"

        cal_hour="$cron_hour"
        [[ "$cron_hour" == "*" ]] && cal_hour="*"

        cal_min="$cron_min"
        [[ "$cron_min" == "*" ]] && cal_min="*"

        if [[ -n "$cal_dow" ]]; then
            on_calendar="$cal_dow *-${cal_month}-${cal_day} ${cal_hour}:${cal_min}:00"
        else
            on_calendar="*-${cal_month}-${cal_day} ${cal_hour}:${cal_min}:00"
        fi

        # Create drop-in override for this timer instance
        override_dir="$TIMER_DIR/argus-task@${instance}.timer.d"
        override_file="$override_dir/schedule.conf"

        override_content="[Timer]
OnCalendar=
OnCalendar=$on_calendar"

        echo "Timer: $instance -> OnCalendar=$on_calendar"

        if [[ "$DRY_RUN" != "--dry-run" ]]; then
            mkdir -p "$override_dir"
            echo "$override_content" > "$override_file"
            systemctl --user enable --now "argus-task@${instance}.timer" 2>/dev/null || true
        fi

    done < <(grep '^### ' "$project_file" | sed 's/^### //')
done

# Report active timers
echo ""
echo "Active Argus timers:"
systemctl --user list-timers 'argus-task@*' --no-pager 2>/dev/null || echo "(none yet)"
