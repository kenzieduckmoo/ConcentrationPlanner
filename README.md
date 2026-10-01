# DuckMoo Services: Concentration Planner

By **DuckMoo Media**. A WoW Retail calendar and daily planner for concentration alts, patron orders, and the many tiny tasks that nibble on a crafting gremlin's brain.

Current addon version: **0.3.0**.

## Install

Copy the `DuckMooPlanner` folder into `_retail_/Interface/AddOns/`, then restart WoW. Open with `/planner`, `/dmp`, or the minimap button. Log into each character and open their crafting professions to collect their data. All displayed times use your local time.

[Full addon guide](DuckMooPlanner/README.md) · [Changelog](DuckMooPlanner/CHANGELOG.md)

## Future updates and builds

This repository is the source of truth. Changes can be reviewed through pull requests. Every push and pull request runs the Lua 5.1 test suite and builds an installable ZIP through GitHub Actions. Open a successful run under **Actions → Test and package addon**, download **DuckMooPlanner-installable**, and extract the enclosed addon ZIP.

These tests mock the WoW APIs. Actual client behavior still needs in-game verification.

To test and package locally on Linux:

```sh
python3 -m pip install -r requirements-dev.txt
python3 DuckMooPlanner/tests/run_tests.py
python3 tools/package.py
```

The ZIP appears in `dist/`. It includes the addon and license, without development tests.

## License

GNU GPL v3, as selected for this repository. See [LICENSE](LICENSE).
