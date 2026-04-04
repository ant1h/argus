---
id: lucidforecast
repo: https://github.com/ant1h/lucidforecast-website
setup_seo-optimizer: scripts/setup-seo-configs.sh
---

# LucidForecast Website

Main LucidForecast website.

## Objectives

- SEO: grow organic traffic through keyword-driven content

## Tasks

### seo-refresh
- **type:** routine
- **schedule:** 0 6 * * 2
- **objective:** Run keyword refresh and content ideas for lucidforecast using the seo-optimizer tool. 1) cd to the seo-optimizer tool dir and run `poetry run seo research --discover lucidforecast` then `poetry run seo content ideas lucidforecast`. 2) Review the generated briefs in the tool's projects/lucidforecast/data/briefs/. 3) If there are actionable briefs, implement the top recommendation in the website repo. Commit changes in the main repo only.
- **tools:**
  - seo-optimizer: https://github.com/ant1h/seo-optimizer
- **resources:**
