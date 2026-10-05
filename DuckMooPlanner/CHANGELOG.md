# 0.4.0

- Replace compact's alt roster with the logged-in character and every visible profession, regardless of whether work is due.
- Show each profession's concentration cap time (or Full now), next patron check date and local AM/PM reset time, plus its Done button.
- Wait until the regional daily reset before showing today's patron tasks in Daily; keep unfinished earlier tasks overdue.
- Preserve early Done, automatic four-day schedules, prior-expansion visibility, opacity, and saved window geometry.
- Keep custom notes in the full planner instead of the character-focused compact dashboard.

# 0.3.0

- Rename display title to DuckMoo Services: Concentration Planner by DuckMoo Media.
- Remove Ready / overdue and already-full bars from weekly view; retain upcoming tasks and forecasts.
- Show compact Done for unscheduled professions; create the default four-day patron schedule and mark it done on click.
- Add a draggable minimap duck-calendar button, settings visibility and slash toggle.
- Pin the logged-in character above a paginated 15-character alt roster.
- Add profession, realm and custom-group filters, search, ascending/descending sorting, and reusable row widgets.
- Add character group creation, rename, confirmed deletion, multiple memberships and bulk assignment across selected pages.
- Separate Settings into Roster, Appearance and About.
- Add full-window opacity, default 85%; retain independent compact opacity, default 65%.
- Restore Daily onboarding/local-time text.
- Add a playful branded About section with user-provided Amazon/social information and copy controls.
- Replace stock buttons/hard outlines with rounded purple surfaces, hover/press feedback, active tabs and status accents.
- Add 400-character/800-profession roster tests and new interaction tests.

# 0.2.0

- Default planner visibility to Midnight; put older entries in a collapsed Prior expansions section with an inclusion toggle. Preserve saved data and explicit Hide choices.
- Add remembered compact Today roster, character grouping and per-profession patron Done buttons.
- Add compact opacity slider, default 65%.
- Add native window resizing, independent sizes/positions by mode, responsive widths, denser rows and shorter headers.
- Add live daily/weekly reset countdowns.
- Add `/planner`, `/planner compact`, `/planner full` and note commands.
- Add dated custom notes, daily-reset/weekly-reset/X-day recurrence, Dismiss, Restore, Edit and confirmed Delete.
- Add custom reminders to calendar, daily/weekly planners and compact view.
- Preserve last view/mode at login.
- Catch one-point Concentration spends when preserving recharge forecasts.
- Expand Lua 5.1 integration/model tests for upgrade behavior and new features.

# 0.1.0

Initial monthly calendar, daily/weekly planners, Concentration snapshots, per-profession patron schedules and crafting roster settings.
