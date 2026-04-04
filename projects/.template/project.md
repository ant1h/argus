---
id: template
repo: https://github.com/ant1h/REPO_NAME
---

# Project Name

Brief description of the project.

## Objectives

- Objective 1
- Objective 2

## KPIs (optional)

- KPI 1

## Tasks

### example-routine
- **type:** routine
- **schedule:** 0 8 * * *
- **objective:** Describe what this routine does each run
- **skills:**
- **resources:**
  - url: https://example.com
  - note: vault/path-to-note
  - local: docs/spec.md

### example-roadmap
- **type:** roadmap
- **schedule:** 0 10 * * 1-5
- **objective:** Pick next roadmap item, implement, submit for review
- **subproject:** (optional, omit to use ROADMAP.md)
