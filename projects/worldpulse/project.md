---
id: worldpulse
repo: https://github.com/ant1h/world-pulse
---

# WorldPulse

Public BI service for financial and economic data at worldpulse.ai. 70+ data sources, point-in-time reconstruction, AI-native architecture.

## Objectives

- Ensure data freshness across all sources
- Detect and fix ingestion failures before they impact users
- Maintain data quality and pipeline reliability

## Tasks

### data-health-check
- **type:** routine
- **schedule:** 0 8 * * *
- **objective:** Check latest data updates across all sources. Identify stale series (not updated within their expected schedule window), failed fetches (consecutive_failures > 0), and any quality issues. For fixable issues (code bugs, config errors), implement the fix and commit. For infrastructure issues (API keys, rate limits, upstream outages), document the problem clearly. Always produce a summary report.
- **skills:**
- **resources:**
  - local: ingestion/jobs/run_fetcher.py
  - local: core/firestore/series.py
  - local: core/firestore/fetch_tracking.py
  - local: ingestion/fetchers/registry.py
  - local: core/quality/checks.py
  - local: config/sources.yaml
  - local: apps/api/routers/admin/fetch_logs.py
