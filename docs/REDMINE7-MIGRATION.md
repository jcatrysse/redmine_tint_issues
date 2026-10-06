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

1. `dues_and_ages` caches the thresholds as absolute dates in a class variable (`@@dues_and_ages`) until the settings change or the process restarts. A long running process therefore keeps comparing against the date of its first request ("younger than 1 day" drifts). Upstream behaviour, present on Redmine 5.1 too. Recommended: compute per request (cheap) or key the cache on the date. Not changed here because it changes behaviour users may rely on; see "Open questions for Jan".
2. Core already adds `overdue` to the row, so the plugin's own `overdue` is a duplicate; harmless, and the red border stays when the module is off (core's own style).
3. `.codex/test_setup.sh` fails as root (`$SUDO -u postgres` with an empty `$SUDO`); here the role was created by hand. Playwright must match the installed Chromium build (`npm install -g playwright@1.56` for `/opt/pw-browsers`). `start_server.sh --reset` can leave a database in which the default data are refused ("already loaded") after an aborted first run; a fresh `RMP_SERVER_DB_NAME` avoids it.

## Open questions for Jan

1. Fix the stale threshold cache (finding 1)? Options: leave as is (identical to what GEOxyz runs today), or compute thresholds per request. Recommendation: fix it in a separate change, it is a real drift bug, but it is not needed for Redmine 7 and changes when rows change colour.

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- None. No migrations, no new settings, no cron. After deploying, the plugin assets are precompiled with the rest of Redmine's assets (Propshaft), nothing extra to do. The existing plugin settings are used unchanged.

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```

```sh
./.codex/start_server.sh       # real Redmine (production mode) with this plugin, seeded users and projects
./.codex/e2e.sh                # browser: smoke over the plugin's pages, core issue flows, test/e2e/*.mjs
./.codex/openai_review.sh      # independent OpenAI review of the diff, only when OPENAI_API_KEY is set
```
Write one scenario per function in `test/e2e/<function>.mjs` (example at the top of
`.codex/e2e/lib.mjs`); screenshots and a table per scenario land in `docs/e2e/`. Users:
`admin`, `manager` (every permission), `reporter` (no plugin permissions), `outsider` (no
membership); password `Redmine7Test!`. Needs Node with Playwright and Chromium
(`npm install -g playwright && npx playwright install --with-deps chromium`).

On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow (tick
"e2e" for the browser run; screenshots come back as an artifact).

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline, before you change anything**:
   - the plugin's tests on Redmine 7.0-stable-GEOxyz with PostgreSQL and with MariaDB;
   - a real running Redmine with this plugin (`./.codex/start_server.sh`) and the browser run
     (`./.codex/e2e.sh`: smoke over every page the plugin adds, plus the core issue flows).
   Write the numbers here. Something already broken now is a finding, not your regression.
3. **Inventory of functions**: list every function of the plugin in this file, in a table
   "function | how a user reaches it | scenario | screenshot". Take them from the README,
   `init.rb` (permissions, menus, settings, project modules), routes, hooks and view
   overrides, macros, mail handling, API endpoints, rake tasks and cron jobs. This table is the
   coverage list for step 8; a function that is not in it will not be tested.
4. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
5. **Work list**: then the numbered list, in order. One concern per commit.
6. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **End to end, visually, every function**: on the real Redmine from `start_server.sh`
   (production mode, the way GEOxyz runs it), write one scenario per function in
   `test/e2e/<function>.mjs` with `.codex/e2e/lib.mjs` and run them with `./.codex/e2e.sh`.
   - Each function as the users that matter: `admin`, `manager` (every permission, the
     plugin's included), `reporter` (member without the plugin's permissions), `outsider`
     (no membership, private project must stay invisible).
   - The failure paths too: setting off, permission absent, empty state, invalid input, the
     value that used to raise. A refusal that is shown is evidence as much as a success.
   - One screenshot per function and per path, with a caption saying what it proves. Open
     every screenshot and look at it: a picture nobody looked at proves nothing. Commit them
     in `docs/e2e/` and list them in the inventory table.
   - Functions without a page (mail in and out, REST API, rake tasks, cron, webhooks): exercise
     them against the same running instance (mails land in `redmine/tmp/mails`, `t.mails()`
     reads them; API through `t.page.request`) and record command and result.
   - Before pictures where behaviour or layout changes: the branch GEOxyz runs today, on
     Redmine 5.1, same scenarios, `RMP_E2E_OUT=docs/e2e/before`.
   - Run the whole e2e set once on MariaDB as well (`RMP_DB=mariadb`, then `start_server.sh --reset`).
9. **Independent review**: first your own, adversarial: re-read the whole diff as if someone
   else wrote it and you are paid to reject it. Then, **when `OPENAI_API_KEY` is set in the
   session**, `./.codex/openai_review.sh`: it sends the diff of this branch to an OpenAI model
   and writes `docs/reviews/openai-<date>-<sha>.md`. Every finding gets a `Resolution:` line
   there (fixed in <commit>, with a test, or why not). Fix, re-run the tests and the e2e set,
   and run the review again until it has nothing new that you accept. Without the key: write
   "OpenAI review: skipped, no OPENAI_API_KEY" in the report; never send code anywhere else.
10. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
    settings, cron, files, removed features) goes into the section "After the upgrade".
11. **Finish**: update "Status", the inventory and the work list in this file, push
    `redmine70-migration`, and report: what changed, test numbers on both databases, e2e
    numbers (scenarios, screenshots, problems), the review result, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service (the OpenAI review of the code diff is the
  one exception Jan approved, and only when the key is present);
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint, browser check or review as passed without having seen
  it. Quote the summary lines; list the screenshots. "Should work" is not a result, and a green
  test suite is not proof that a feature works in the browser.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module, sudo mode
  (on by default: `t.sudo()` in a scenario). The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why). Push after every
  commit, together with the updated status in this file: a cloud session can stop at a usage
  limit, and work that is not pushed is lost with its container.
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every function in the inventory exercised end to end on a real running Redmine, with and
  without permissions and on its failure paths; `./.codex/e2e.sh` green; screenshots looked at,
  committed in `docs/e2e/` and listed.
- Review done: your own, and the OpenAI review when the key is present, every finding resolved
  in `docs/reviews/`.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_tint_issues
- Gebruikte branch: master @ a7f80d1 (2025-04-27) - plugin id redmine_tint_issues, versie 1.3.2
- Upstream: HugoHasenbein/redmine_tint_issues - upstream HEAD master @ 3d71bdc (2022-07-01, v1.3.2)
- Fork t.o.v. upstream: 1 eigen commit (a7f80d1 "Resolve typo in html style"), 0 upstream-commits ontbreken.
- Andere relevante branches: geen (upstream heeft alleen master). Geen onderhouden fork gevonden (korte zoektocht). redmine.org vermeldt compatibiliteit tot 5.0.
- Opbouw: patch op `Issue#css_classes` (alias_method, `lib/redmine_tint_issues/patches/issue_patch.rb:31-37`), helpermethodes op ApplicationHelper, CSS via de head-hook (`render_on :view_layouts_base_html_head` -> `content_for :header_tags`), projectmodule + permission, instellingen met jscolor.js. Geen Gemfile, migraties of tests.

## 1. Werkt out of the box op Redmine 7?   JA
- Harness (`results/1006-085449-s1-redmine_tint_issues_origin_master`): boot OK, eager OK, migraties OK, smoke 60/60.
- Functioneel in de browser (module aan, leeftijds-, due- en kleurinstellingen gezet): issuelijst-rijen krijgen de klassen (`current`, `veryold`, `overdue`) en de achtergrondkleur (bv. issue-1 `veryold overdue` -> rgb(255,153,153) + 10px rand rgb(136,0,0); de rest `current` -> groen, odd/even afwisselend). `Issue#css_classes(user=User.current)` heeft in R7 dezelfde signatuur en levert een niet-bevroren string, dus `s << ...` werkt.

## 2. Upstream sync?   UPSTREAM DOOD
- Laatste upstream-commit 2022-07-01, niets nieuwer. De fork bevat alles plus één typo-fix.

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 1
- Blokkers: geen.
- Stille breuken:
  - Instellingenpagina: jscolor.js zoekt zijn eigen map via de scriptnaam (`assets/javascripts/jscolor.js:37-42`). Onder Propshaft heet het script `jscolor-<digest>.js`, de autodetectie faalt en de picker-afbeeldingen worden relatief gezocht: gemeten 404 op `/settings/plugin/jscolor/cross.gif`, `arrow.gif`, `hs.png`. De kleurkiezer toont geen kleurvlak meer; hexcodes typen werkt nog. Komt door Propshaft (R6+); op 5.1 werkte het.
  - `_settings.html.erb:162` laadt `redmine_tint_issues.css`, dat niet in de plugin bestaat -> 404 (bestaand, al op 5.1).
  - `icon icon-help` op de instellingenpagina (`_settings.html.erb:148,154`): icoon weg (#43206), cosmetisch.
  - Kleine dubbel: core zet zelf al `overdue` op de rij, de plugin voegt het nog eens toe (onschadelijk).
- Overlap met Redmine 7 core: geen (core kleurt alleen op prioriteit/status via CSS-klassen).
- Open werk voor ansif:
  1. jscolor-afbeeldingen onder Propshaft: `jscolor.dir` niet bruikbaar met digests. Bv. de afbeeldingen als `asset_path` doorgeven, of de `<input type="color">` van de browser gebruiken. Cosmetisch, admin-only.
  2. Ontbrekende `redmine_tint_issues.css`-referentie weghalen.

## Branch redmine70-migration
- Basis: origin/master @ a7f80d1 (geen wijzigingen nodig)
- Commits: geen (branch = origin/master)
- Eindresultaat harness (`results/1006-095919-s1-redmine_tint_issues_redmine70-migration`): boot OK, eager OK, migraties OK, smoke 60/60 (geen tests in de plugin)
- Rollback migraties: n.v.t. (geen migraties)

