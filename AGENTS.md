# Development instructions

This repository is the source of truth for DuckMoo Services: Concentration Planner by DuckMoo Media.

- Fetch the latest remote state before making future updates. Preserve other contributors' changes.
- Addon source lives in DuckMooPlanner/. Keep that folder name and DuckMooPlannerDB stable.
- Target WoW Retail and Lua 5.1. Never call protected crafting APIs to open professions automatically.
- Preserve saved variables with migrations when changing stored data.
- Run `python3 DuckMooPlanner/tests/run_tests.py` and `python3 tools/package.py` before committing.
- Document user-visible changes in DuckMooPlanner/CHANGELOG.md and update the TOC version for releases.
- Keep times local and in AM/PM, weekly forecasts upcoming-only, and large character rosters usable.
- Report in-game verification separately from mocked tests. Do not claim client testing without doing it.
- Use a branch and pull request for future changes unless the user requests direct updates to main.
- Do not commit player SavedVariables, credentials, build output, or local environments.
