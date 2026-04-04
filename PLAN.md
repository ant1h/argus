# Argus - Implementation Plan

## Principles

- Simplicity: md files, Claude Code, systemd timers
- Iterative: start minimal, add capabilities based on usage
- Agent autonomy with review gates: auto-deploy clear tasks, flag ambiguous ones for Antoine

## Architecture

### Argus repo (this repo) — the control plane

```
argus/
├── PLAN.md
├── repos/                          # git-ignored agent working copies (auto-cloned)
├── projects/
│   └── <project-id>/
│       ├── project.md          # repo url, tasks, resources, schedule
│       └── logs/
│           └── <task-id>/
│               └── <timestamp>.md
├── STATUS.md                   # auto-generated dashboard: last run per task, status overview
├── skills/                     # claude code skills used by tasks
└── automation/
    └── systemd/                # timer + service templates
```

### Per-project repo — the work surface

```
repo-root/
├── PROJECT.md                  # objectives, KPIs, subproject index
├── ROADMAP.md                  # single roadmap (simple projects)
├── roadmaps/                   # multiple roadmaps (complex projects)
│   └── <subproject>.md
└── docs/                       # local resources (specs, notes)
```

## Data Model

### project.md (in Argus)

```yaml
---
id: my-project
repo: https://github.com/ant1h/my-project
---
```

Tasks defined as sections:

```markdown
## Tasks

### daily-check
- **type:** routine
- **schedule:** 0 8 * * *
- **objective:** Check build status and report
- **skills:** /commit
- **resources:**
  - url: https://example.com/docs
  - note: vault/project-notes
  - local: docs/spec.md

### roadmap-work
- **type:** roadmap
- **schedule:** 0 10 * * 1-5
- **objective:** Pick next roadmap item, implement, submit for review
- **subproject:** backend (optional, defaults to ROADMAP.md)
```

### ROADMAP.md (in project repo)

```markdown
## Item title
- **status:** todo | in_progress | review | done
- **priority:** p0 | p1 | p2
- **depends_on:** other item title (optional)
- **assigned:** agent | antoine | both

What needs to happen.
```

### Log entry format

```markdown
---
task: daily-check
project: my-project
timestamp: 2026-04-04T08:00:00
status: success | failed | needs_review
---

## What happened
- Ran build check, all green
- No action needed

## Artifacts
- commit: abc123 (if any)
- pr: #42 (if any)
```

### STATUS.md (auto-generated)

| Project | Task | Last Run | Status | Next Run |
|---------|------|----------|--------|----------|
| my-project | daily-check | 2026-04-04 08:00 | success | 2026-04-05 08:00 |
| my-project | roadmap-work | 2026-04-04 10:00 | needs_review | 2026-04-07 10:00 |

## Resource Types

- **url:** web page
- **note:** Obsidian vault reference (via MCP)
- **local:** file inside the project repo
- **gcs:** documents in GCS (future — not yet set up)

## Implementation Steps

### Phase 1 — Scaffolding
1. Create Argus folder structure (`projects/`, `skills/`, `automation/`)
2. Define a real first project with `project.md`
3. Set up `PROJECT.md` and `ROADMAP.md` in that project's repo
4. Write the `STATUS.md` generation logic (simple script or skill)

### Phase 2 — First task end-to-end
5. Pick one concrete routine task for the first project
6. Write a runner script: reads `project.md` → invokes Claude Code on the repo → writes log → updates STATUS.md
7. Create systemd timer + service for that one task
8. Test manually, then let it run on schedule

### Phase 3 — Roadmap tasks
9. Write roadmap task logic: read ROADMAP.md → pick next item (priority + dependencies + assigned) → work on it → update status
10. Add review gate: if task result is ambiguous, set roadmap item to `review` and notify Antoine
11. Wire up with systemd timer

### Phase 4 — Expand
12. Add more projects and tasks based on what works
13. Refine skills library based on common patterns
14. Add GCS resource support when ready
