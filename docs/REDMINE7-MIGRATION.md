# Redmine 7 migration: redmine_tint_issues

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. That includes the plugin's tests on
> PostgreSQL and MariaDB, every function exercised end to end on a real running Redmine in a
> browser (with and without permissions, failure paths included) with screenshots you looked at,
> and an OpenAI review of the diff when OPENAI_API_KEY is set. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_tint_issues` |
| GEOxyz runs today | `master` |
| Upstream | HugoHasenbein/redmine_tint_issues master @ 3d71bdc6166b9ad9334e2cfa67de60d1c308a9b3 (2022-07-01) |
| Runs on Redmine 7 as is | JA (settings page cosmetics fixed on this branch) |
| Upstream sync | UPSTREAM DOOD: nothing; fork = upstream 1.3.2 + 1 typo fix |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 1 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `711e67b` |

## Already on this branch

- Settings page fixes (items 1 to 3 below), unit and functional tests (`test/`), e2e scenarios and seed (`test/e2e/`).

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Open items from the analysis** (Dutch; where they conflict with a decision or a priority item above, those win)

1. Settings page: jscolor.js autodetects its dir from the script name, which Propshaft digests -> picker images 404 (/settings/plugin/jscolor/hs.png etc.), colour field without gradient (typing hex still works)
2. _settings.html.erb:162 references non-existent redmine_tint_issues.css (404, pre-existing)
3. icon icon-help on settings page lost (#43206), cosmetic

**Checks**

4. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
5. Check Redmine 7 webhooks against this plugin (see "Rules"), and note the result here even if nothing is needed.
6. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).

## GEOxyz changes to review or re-apply

These GEOxyz commits are on the branch GEOxyz runs today and therefore on this branch. Review each one against the code it now sits on (upstream merges and Redmine 7 core): drop it if upstream or core now does the same, rewrite it if it is not up to the quality rules below (tests, I18n, security, portability), keep it otherwise. Record the verdict per commit in this file.

| commit | date | subject |
|---|---|---|
| `a7f80d1` | 2025-04-27 | * Resolve typo in html style |

**Verdict `a7f80d1`: kept.** It is a CSS typo fix in the plugin's own settings markup, upstream has nothing newer, core does not do this. No behaviour change. It fixes `width=33%` to `width:33%` in the settings table (inline CSS); verified visually in the settings e2e scenario.

## Results (2026-10-06, branch `redmine70-migration`)

**Work list**

| item | result |
|---|---|
| 1 jscolor images under Propshaft | fixed: `jscolor.imageUrls` (filename to digested `asset_path`), `rti_jscolor_images` helper, picker shown with colour square in the e2e screenshot `settings-picker.png`. jscolor already owns `jscolor.images`, hence the name. Redmine < 6 keeps the script directory detection. |
| 2 missing `redmine_tint_issues.css` | removed from the settings partial |
| 3 `icon icon-help` | `rti_help_link`: `sprite_icon('help')` with `icon-only icon-help` on Redmine >= 6, old markup before |
| 4 tests on PG and MariaDB | see numbers below |
| 5 webhooks | checked: the plugin only adds CSS classes to list rows (`Issue#css_classes`) and a settings page; it hides, adds and changes no issue data and no API output. Core's `issues/show.api.rsb` webhook payload needs nothing from the plugin. Nothing to do. |
| 6 every function by hand | see inventory |

**Numbers**

| | PostgreSQL 16 | MariaDB 10.11 |
|---|---|---|
| plugin tests on 7.0-stable-GEOxyz (Redmine 7.0.1, Rails 8.1.3.1, Ruby 3.3.6) | 16 runs, 90 assertions, 0 failures | 16 runs, 90 assertions, 0 failures |
| e2e (`e2e.sh`: smoke 10, core 6, settings 7, tint-issues 8 screenshots) | 0 problems | 0 problems (`docs/e2e/mariadb/`) |

- Baseline before any change: no tests in the plugin, smoke 10 screenshots and core 6 screenshots, 0 problems. The settings page was not in the smoke (no `app/views/settings`); the picker 404s of the analysis were reproduced as `jscolor.picker` failing (TypeError) once opened.
- 6.1-stable (PostgreSQL): 16 runs, 77 assertions, 0 failures. 5.1-stable: not run, the checkout needs Ruby < 3.3 and this environment has 3.3.6 only. The 5.1 paths (`respond_to?(:sprite_icon)`, `Redmine::VERSION::MAJOR >= 6`) are covered by the 6.1 not 5.1 run only, say so when merging to a 5.1 line.
- No migrations, so nothing to run down and up. Production mode boots and eager loads (the e2e server runs in production mode).
- Together with the other GEOxyz plugins: not run (no other plugin checkouts attached); the plugin only patches `Issue#css_classes` and adds two helper methods to ApplicationHelper (`rti_` prefix), a conflict is unlikely.
- OpenAI review (`docs/reviews/openai-2026-10-06-3b2b82f.md`): no findings.
- My own adversarial read of the diff: help link id and picker urls are fixed strings, `to_json` escaped, no params in SQL, no new setting, no schema change.

**Inventory of functions**

| function | how a user reaches it | scenario | screenshots |
|---|---|---|---|
| Project module "Tint Issues" (on/off per project) | Project settings, information tab | `tint-issues.mjs` | `tint-issues-module-settings-off`, `-list-after-off`, `-list-after-on`, `-list-module-off` |
| Row tint by issue age (current, old, older, veryold, ancient), age base creation or update date, start date wins | issue list of a project with the module | `tint-issues.mjs` + unit tests | `tint-issues-list-manager` |
| Row border by due date (hasduedate, due, moredue, verydue, overdue), none for closed issues | same | same | same |
| Same for a member without plugin permissions, and an outsider (permission `view_issue_tint` is public and empty: the module decides, not the permission) | issue list as reporter / outsider | same | `tint-issues-list-reporter`, `-list-outsider`, `-outsider-private` |
| Head CSS hook (`view_layouts_base_html_head`) | every page | covered by the list scenario (computed colours asserted) | |
| Settings page: thresholds, units, colours, colour picker, help texts, save | Administration, Plugins, Configure | `settings.mjs` + functional test | `settings-page`, `-picker`, `-help`, `-saved`, `-list-after-save` |
| Settings refused for non-admin, login redirect for anonymous | same URL | `settings.mjs` | `settings-manager-refused`, `settings-anonymous-login` |

No routes, mail, API, rake tasks or cron jobs exist in this plugin.

**Findings, not fixed (outside the migration, minimal diff rule)**

1. `dues_and_ages` cached the thresholds as absolute dates in a class variable until a restart or settings change, so "younger than 1 day" drifted in a long running process (upstream, also on 5.1). **Fixed on Jan's go-ahead** ("pas maar aan"): the cache key is the settings plus the current minute; test `thresholds follow the clock` fails without the fix (17 runs, 94 assertions green with it on PostgreSQL; e2e re-run green). The `ages_calculated` pseudo setting is gone.
2. Core already adds `overdue` to the row, so the plugin's own `overdue` is a duplicate; harmless, and the red border stays when the module is off (core's own style).
3. `.codex/test_setup.sh` fails as root (`$SUDO -u postgres` with an empty `$SUDO`); here the role was created by hand. Playwright must match the installed Chromium build (`npm install -g playwright@1.56` for `/opt/pw-browsers`). `start_server.sh --reset` can leave a database in which the default data are refused ("already loaded") after an aborted first run; a fresh `RMP_SERVER_DB_NAME` avoids it.

## Open questions for Jan

1. Stale threshold cache: decided by Jan, fixed (see finding 1). Nothing open.
