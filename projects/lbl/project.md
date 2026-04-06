---
id: lbl
repo: https://github.com/ant1h/lbl-website
setup_seo-optimizer: scripts/setup-seo-configs.sh
---

# LBL Website

## Objectives

- SEO: grow organic traffic through keyword-driven content

## Tasks

### seo-refresh
- **type:** routine
- **schedule:** 0 6 * * 4
- **objective:** Run keyword refresh and content ideas for lbl using the seo-optimizer tool. 1) cd to the seo-optimizer tool dir and run `poetry run seo -p lbl research --discover` then `poetry run seo -p lbl ideate`. 2) Review the generated briefs in the tool's projects/lbl/data/briefs/. 3) If there are actionable briefs, implement the top recommendation in the website repo. Commit changes in the main repo only.
- **tools:**
  - seo-optimizer: https://github.com/ant1h/seo-optimizer
- **resources:**
