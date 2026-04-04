---
id: worldpulse
repo: https://github.com/ant1h/world-pulse
setup_seo-optimizer: scripts/setup-seo-configs.sh
---

# WorldPulse

Public BI service for financial and economic data at worldpulse.ai. 70+ data sources, point-in-time reconstruction, AI-native architecture.

## Objectives

- Ensure data freshness across all sources
- Detect and fix ingestion failures before they impact users
- Maintain data quality and pipeline reliability
- SEO: grow organic traffic through keyword-driven content

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

### seo-refresh
- **type:** routine
- **schedule:** 0 6 * * 1
- **objective:** Run keyword refresh and content ideas for worldpulse using the seo-optimizer tool. 1) cd to the seo-optimizer tool dir and run `poetry run seo research --discover worldpulse` then `poetry run seo content ideas worldpulse`. 2) Review the generated briefs in the tool's projects/worldpulse/data/briefs/. 3) If there are actionable briefs, implement the top recommendation in the website repo (create/update pages, meta tags, content). Commit changes in the main repo only.
- **tools:**
  - seo-optimizer: https://github.com/ant1h/seo-optimizer
- **resources:**
  - local: apps/web/
