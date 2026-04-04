
Argus


Design principle
1 - Simplicity: mostly md files, claude code and simple automation tool, no UI for now
2- iterative development & continuous improvement: start, with basics only, test, carefully add capabilities based on usage

Validation principles
follow best practices in term of product dev: problem framing -> solution -> development -> testing -> validation & improvement -> deployment (TBD)
key approach: the agents should be able to decide between clear validation (simple tasks / very clear test results), deploy and potentially move to next step versus tasks implementation that need Antoine review.


Tech stack
Claude Code act as the main brain an execution tool
Claude skills
Simple automation setup on my ubuntu (TBD)
Github: every project has its repo that agents can pull to work on
We also probably need some python/poetry setup

Ressources
- obisidian notes (currently MCP, should probably refactored to simpler API). A tasks can have reference to a specific note
- documents: key documents that can be referered in tasks: ebouks, articles stored in GCS
- websites url


Projects Formats
- projects id, objectives, KPI (optional)
- subprojects (optional) id, objectives, KPI (optional)
- repo url
- tasks

Tasks format
- id, objectives
- frequency (probably cron formats, depends on automation choice)
- task type: we need to find the right typology. For now i see routines = task that do ~similar work each time. And roadmap task that pick up what need to be done in a roadmap, then update roadmap.
- ressources
- skills