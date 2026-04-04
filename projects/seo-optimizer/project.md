---
id: seo-optimizer
repo: https://github.com/ant1h/seo-optimizer
setup: scripts/setup-seo-configs.sh
---

# SEO Optimizer

Multi-site SEO research & content planning tool. Fetches data from GSC, GA4, Google Ads, DataForSEO and generates keyword analysis + content briefs.

## Objectives

- Keep keyword data fresh across all 6 sites
- Generate actionable content recommendations
- Monitor ranking changes and opportunities

## Tasks

### seo-worldpulse
- **type:** routine
- **schedule:** 0 6 * * 1
- **objective:** Run keyword refresh and content ideas for worldpulse. Use the CLI: `poetry run seo research --discover worldpulse`, then `poetry run seo content ideas worldpulse`.
- **resources:**
  - local: projects/worldpulse/config/credentials.yaml

### seo-lucidforecast
- **type:** routine
- **schedule:** 0 6 * * 2
- **objective:** Run keyword refresh and content ideas for lucidforecast.
- **resources:**
  - local: projects/lucidforecast/config/credentials.yaml

### seo-babygram
- **type:** routine
- **schedule:** 0 6 * * 3
- **objective:** Run keyword refresh and content ideas for babygram.
- **resources:**
  - local: projects/babygram/config/credentials.yaml

### seo-bme
- **type:** routine
- **schedule:** 0 6 * * 3
- **objective:** Run keyword refresh and content ideas for bme.
- **resources:**
  - local: projects/bme/config/credentials.yaml

### seo-lbl
- **type:** routine
- **schedule:** 0 6 * * 4
- **objective:** Run keyword refresh and content ideas for lbl.
- **resources:**
  - local: projects/lbl/config/credentials.yaml

### seo-thesignal
- **type:** routine
- **schedule:** 0 6 * * 4
- **objective:** Run keyword refresh and content ideas for thesignal.
- **resources:**
  - local: projects/thesignal/config/credentials.yaml
