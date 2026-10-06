// Function: plugin settings page (administration > plugins > configure): thresholds, colours, colour picker, help texts, age base.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('settings');
const SETTINGS = '/settings/plugin/redmine_tint_issues';
const expect = (cond, msg) => { if (!cond) t.problems.push(msg); };

await t.login('admin');
await t.go(SETTINGS);
await t.shot('page', 'Settings page: ages and due thresholds with unit selects, colour fields, age base radios');
expect(await t.page.locator('input.color').count() === 10, 'expected 10 colour fields');

// colour picker: opens and its images load (these 404ed under Propshaft before the fix)
await t.page.click('input[name="settings[current_issue_age_color]"]');
await t.page.waitForFunction(() => window.jscolor && jscolor.picker && jscolor.picker.boxB.style.display !== 'none');
await t.shot('picker', 'Colour picker open with colour square and slider (images served from /assets/plugin_assets/)', { full: false });
const imgs = [await t.page.evaluate(() => jscolor.picker.pad.style.backgroundImage)];
expect(imgs.some(i => /plugin_assets\/redmine_tint_issues\/hs-[0-9a-f]+\.png/.test(i)), 'picker pad image not the digested asset: ' + imgs.join(' '));
t.check('colour picker');

// help texts toggle
await t.page.click('a[onclick*="help_settings_age_by_creation_date"]');
expect(await t.page.locator('#help_settings_age_by_creation_date').isVisible(), 'help text not shown');
await t.shot('help', 'Help icon (SVG) toggles the explanation of the age base');

// save: change a value, switch the age base, reload and see it persisted
await t.page.keyboard.press('Escape');
await t.page.fill('input[name="settings[current_issue_age]"]', '2');
await t.page.fill('input[name="settings[current_issue_age_color]"]', '#aaffaa');
await t.page.check('input[name="settings[age_by_creation_date]"][value="0"]');
await t.page.click('#content form input[type=submit][name=commit]');
await t.settle();
await t.sudo();
await t.go(SETTINGS);
expect(await t.page.inputValue('input[name="settings[current_issue_age]"]') === '2', 'value not saved');
expect((await t.page.inputValue('input[name="settings[current_issue_age_color]"]')).toLowerCase() === '#aaffaa', 'colour not saved');
expect(await t.page.isChecked('input[name="settings[age_by_creation_date]"][value="0"]'), 'age base not saved');
await t.shot('saved', 'After saving and reloading: new values persisted');

// the new setting is active in the list (age 2 days + colour)
await t.go('/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id');
const bg = await t.page.$eval('table.list.issues tbody tr.issue.current', tr => getComputedStyle(tr).backgroundColor).catch(() => null);
expect(bg !== null, 'no current row after the change');
await t.shot('list-after-save', 'List uses the saved colours');

// restore the seeded values
await t.go(SETTINGS);
await t.page.fill('input[name="settings[current_issue_age]"]', '1');
await t.page.fill('input[name="settings[current_issue_age_color]"]', '#99ff99');
await t.page.check('input[name="settings[age_by_creation_date]"][value="1"]');
await t.page.click('#content form input[type=submit][name=commit]');
await t.settle();
await t.sudo();

// failure paths: not allowed for non-admins
await t.login('manager');
await t.go(SETTINGS, { status: 403 });
await t.shot('manager-refused', 'A non-administrator is refused');
await t.anonymous();
await t.page.goto(t.BASE + SETTINGS);
await t.settle();
expect(new URL(t.page.url()).pathname === '/login', 'anonymous not sent to login');
await t.shot('anonymous-login', 'Anonymous is sent to the login page');
await t.done();
