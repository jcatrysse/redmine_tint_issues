# Plugin data for the end-to-end run: thresholds and colours, issues of every age and due
# class in e2e-project, the project module off in e2e-private. Idempotent.
settings = {
  'age_by_creation_date' => '1',
  'current_issue_age' => '1',  'current_issue_age_epoch' => 'days',   'current_issue_age_color' => '#99ff99',
  'old_issue_age' => '1',      'old_issue_age_epoch' => 'weeks',      'old_issue_age_color' => '#ffff99',
  'older_issue_age' => '1',    'older_issue_age_epoch' => 'months',   'older_issue_age_color' => '#ffcc99',
  'veryold_issue_age' => '6',  'veryold_issue_age_epoch' => 'months', 'veryold_issue_age_color' => '#ff9999',
  'ancient_issue_age_color' => '#cccccc',
  'hasduedate_color' => '#0000ff',
  'due_since' => '3',          'due_since_epoch' => 'days',           'due_since_color' => '#00ccff',
  'moredue_since' => '2',      'moredue_since_epoch' => 'days',       'moredue_since_color' => '#ff9900',
  'verydue_since' => '1',      'verydue_since_epoch' => 'days',       'verydue_since_color' => '#ff3300',
  'overdue_color' => '#880000'
}
Setting.plugin_redmine_tint_issues = settings

project = Project.find_by!(identifier: 'e2e-project')
private_project = Project.find_by!(identifier: 'e2e-private')
project.enable_module!(:redmine_tint_issues)
private_project.disable_module!(:redmine_tint_issues)

now = Time.now
{ 'E2E assigned issue'   => [now - 1.hour,   Date.today + 7],
  'E2E unassigned issue' => [now - 3.days,   Date.today + 3],
  'E2E subtask'          => [now - 3.weeks,  Date.today + 1],
  'E2E related issue'    => [now - 2.months, Date.today - 2],
  'E2E closed issue'     => [now - 8.months, nil] }.each do |subject, (created, due)|
  issue = Issue.find_by!(project_id: project.id, subject: subject)
  attrs = { created_on: created }
  attrs[:due_date] = due if due
  issue.update_columns(attrs)
end
Issue.find_by!(project_id: private_project.id, subject: 'E2E private issue').update_columns(created_on: now - 8.months)
puts 'Tint issues seeded.'
