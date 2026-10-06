// Function: tinting of issue rows by age and due date (module "Tint Issues", Issue#css_classes + head CSS).
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('tint-issues');
const LIST = '/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id';
const expect = (cond, msg) => { if (!cond) t.problems.push(msg); };

async function rows(page) {
  return page.$$eval('table.list.issues tbody tr.issue', trs => trs.map(tr => {
    const cs = getComputedStyle(tr);
    return { subject: tr.querySelector('td.subject')?.textContent.trim(), cls: tr.className.split(/\s+/),
             bg: cs.backgroundColor, border: cs.borderLeftColor, bw: cs.borderLeftWidth };
  }));
}
const by = (rs, subject) => rs.find(r => r.subject === subject) || { cls: [] };

// 1. manager: module on, every age and due class present with its colour
await t.login('manager');
await t.go(LIST);
let rs = await rows(t.page);
const want = {
  'E2E assigned issue':   ['current', 'hasduedate'],
  'E2E unassigned issue': ['old', 'due'],
  'E2E subtask':          ['older', 'verydue'],
  'E2E related issue':    ['veryold', 'overdue'],
  'E2E closed issue':     ['ancient'],
};
for (const [subject, classes] of Object.entries(want)) {
  const r = by(rs, subject);
  for (const c of classes) expect(r.cls.includes(c), `${subject}: class ${c} missing, has ${r.cls.join(' ')}`);
}
expect(by(rs, 'E2E closed issue').cls.every(c => !['hasduedate', 'due', 'moredue', 'verydue', 'overdue'].includes(c)), 'closed issue has a due class');
expect(by(rs, 'E2E related issue').border === 'rgb(136, 0, 0)' && by(rs, 'E2E related issue').bw === '10px', 'overdue border not #880000/10px: ' + JSON.stringify(by(rs, 'E2E related issue')));
expect(['rgb(255, 153, 153)', 'rgb(255, 166, 166)'].includes(by(rs, 'E2E related issue').bg), 'veryold background: ' + by(rs, 'E2E related issue').bg);
expect(['rgb(204, 204, 204)', 'rgb(217, 217, 217)'].includes(by(rs, 'E2E closed issue').bg), 'ancient background: ' + by(rs, 'E2E closed issue').bg);
await t.shot('list-manager', 'Module on: rows tinted by age (background) and due date (10px side borders), as the manager');

// 2. reporter: no plugin permission needed, the module decides (permission view_issue_tint is public)
await t.login('reporter');
await t.go(LIST);
rs = await rows(t.page);
expect(by(rs, 'E2E related issue').cls.includes('veryold'), 'reporter does not see the tint');
await t.shot('list-reporter', 'A member without plugin permissions sees the same tint (the module, not the permission, switches it)');

// 3. module off: private project, same age of issue, no tint classes and no colour
await t.login('manager');
await t.go('/projects/e2e-private/issues?set_filter=1&status_id=*');
rs = await rows(t.page);
const priv = by(rs, 'E2E private issue');
expect(rs.length > 0 && !priv.cls.some(c => ['current', 'old', 'older', 'veryold', 'ancient'].includes(c)), 'module off but tint class present: ' + priv.cls.join(' '));
await t.shot('list-module-off', 'Module off in this project: an 8 months old issue gets no tint class and no colour');

// 4. switching the module off and on in the project settings
await t.go('/projects/e2e-project/settings');
await t.page.uncheck('#project_enabled_module_names_redmine_tint_issues');
await t.shot('module-settings-off', 'Project settings, information tab: module Tint Issues unchecked');
await t.page.click('form.edit_project input[type=submit][name=commit]');
await t.settle();
await t.go(LIST);
rs = await rows(t.page);
expect(by(rs, 'E2E related issue').cls.every(c => c !== 'veryold'), 'tint remains after switching the module off');
await t.shot('list-after-off', 'After switching the module off the tint is gone (only core's own red overdue border of #4 remains)');
await t.go('/projects/e2e-project/settings');
await t.page.check('#project_enabled_module_names_redmine_tint_issues');
await t.page.click('form.edit_project input[type=submit][name=commit]');
await t.settle();
await t.go(LIST);
rs = await rows(t.page);
expect(by(rs, 'E2E related issue').cls.includes('veryold'), 'tint missing after switching the module on');
await t.shot('list-after-on', 'Module on again: tint is back');

// 5. outsider: private project stays invisible
await t.login('outsider');
await t.go('/projects/e2e-private/issues', { status: 403 });
await t.shot('outsider-private', 'Outsider: the private project is refused');
await t.go(LIST);
rs = await rows(t.page);
expect(by(rs, 'E2E related issue').cls.includes('veryold'), 'outsider does not see the tint in the public project');
await t.shot('list-outsider', 'Outsider: public project list is tinted as for everybody');
await t.done();
