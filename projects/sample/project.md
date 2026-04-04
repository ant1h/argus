---
id: sample
repo: https://github.com/ant1h/argus
---

# Sample Project

A test project pointing at the Argus repo itself, used to validate the pipeline.

## Objectives

- Verify the Argus runner works end-to-end

## Tasks

### health-check
- **type:** routine
- **schedule:** 0 9 * * *
- **objective:** Check that the Argus repo is in a clean state: no uncommitted changes, scripts are executable, STATUS.md is up to date. Report findings.
- **skills:**
- **resources:**
  - local: PLAN.md
