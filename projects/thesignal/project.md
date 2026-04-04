---
id: thesignal
repo: https://github.com/ant1h/thesignal-website
setup_seo-optimizer: scripts/setup-seo-configs.sh
---

# The Signal Website

Economic and financial forecasts by AIs and humans.

## Objectives

- SEO: grow organic traffic through keyword-driven content

## Tasks

### seo-refresh
- **type:** routine
- **schedule:** 0 6 * * 4
- **objective:** Run keyword refresh and content ideas for thesignal using the seo-optimizer tool. 1) cd to the seo-optimizer tool dir and run `poetry run seo research --discover thesignal` then `poetry run seo content ideas thesignal`. 2) Review the generated briefs in the tool's projects/thesignal/data/briefs/. 3) If there are actionable briefs, implement the top recommendation in the website repo. Commit changes in the main repo only.
- **tools:**
  - seo-optimizer: https://github.com/ant1h/seo-optimizer
- **resources:**
