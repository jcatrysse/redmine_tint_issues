# encoding: utf-8
require File.expand_path('../../../../../test/test_helper', __FILE__)

class IssueTintTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :issues, :versions

  def setup
    @issue = Issue.find(1)
    @issue.project.enable_module!(:redmine_tint_issues)
    @issue.update_columns(:start_date => nil, :due_date => nil, :created_on => Time.now, :updated_on => Time.now)
  end

  def tint(settings = {}, &block)
    RedmineTintIssues::Current.reset
    with_settings({'plugin_redmine_tint_issues' => {'age_by_creation_date' => '1'}.merge(settings)}, &block)
  end

  def classes(issue = @issue.reload)
    issue.css_classes.split
  end

  test "no tint classes when the project module is off" do
    @issue.project.disable_module!(:redmine_tint_issues)
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') do
      assert_not_includes classes(Issue.find(1)), 'current'
      assert_not_includes classes(Issue.find(1)), 'ancient'
    end
  end

  test "no tint classes without any setting" do
    tint do
      assert_equal [], classes & %w(current old older veryold ancient hasduedate due moredue verydue overdue)
    end
  end

  test "age classes follow the thresholds" do
    ages = {'current_issue_age' => '1', 'current_issue_age_epoch' => 'days',
            'old_issue_age' => '1', 'old_issue_age_epoch' => 'weeks',
            'older_issue_age' => '1', 'older_issue_age_epoch' => 'months',
            'veryold_issue_age' => '6', 'veryold_issue_age_epoch' => 'months'}
    {1.hour => 'current', 3.days => 'old', 3.weeks => 'older', 2.months => 'veryold'}.each do |age, expected|
      @issue.update_columns(:created_on => Time.now - age)
      tint(ages) { assert_includes classes, expected, "age #{age.inspect}" }
    end
    @issue.update_columns(:created_on => Time.now - 8.months)
    tint(ages) { assert_includes classes, 'ancient' }
  end

  test "age base is the update date when configured" do
    @issue.update_columns(:created_on => Time.now - 2.years, :updated_on => Time.now)
    ages = {'current_issue_age' => '1', 'current_issue_age_epoch' => 'days'}
    tint(ages.merge('age_by_creation_date' => '0')) { assert_includes classes, 'current' }
    tint(ages.merge('age_by_creation_date' => '1')) { assert_includes classes, 'ancient' }
  end

  test "start date takes precedence over the age base" do
    @issue.update_columns(:created_on => Time.now - 2.years, :start_date => Date.today)
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') { assert_includes classes, 'current' }
  end

  test "due classes follow the thresholds" do
    due = {'due_since' => '3', 'due_since_epoch' => 'days',
           'moredue_since' => '2', 'moredue_since_epoch' => 'days',
           'verydue_since' => '1', 'verydue_since_epoch' => 'days'}
    {Date.today + 10 => 'hasduedate', Date.today + 3 => 'due', Date.today + 2 => 'moredue',
     Date.today + 1 => 'verydue', Date.today => 'verydue', Date.today - 1 => 'overdue'}.each do |date, expected|
      @issue.update_columns(:due_date => date)
      tint(due) { assert_includes classes, expected, "due #{date}" }
    end
  end

  test "closed issues get no due class" do
    @issue.update_columns(:due_date => Date.today - 5, :status_id => IssueStatus.where(:is_closed => true).first.id)
    tint('due_since' => '3', 'due_since_epoch' => 'days') do
      assert_equal [], classes & %w(hasduedate due moredue verydue)
    end
  end

  test "settings change is picked up after the settings are replaced" do
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') { assert_includes classes, 'current' }
    @issue.update_columns(:created_on => Time.now - 3.days)
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') { assert_includes classes, 'ancient' }
  end

  test "thresholds follow the clock, not the time of the first request" do
    @issue.update_columns(:created_on => Time.now - 20.hours)
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') do
      assert_includes classes, 'current'
      travel 5.hours do
        RedmineTintIssues::Current.reset # thresholds are fixed per request
        assert_includes classes, 'ancient'
      end
    end
  end

  test "css_classes is prepended, so it coexists with other plugins prepending the same method" do
    mod = RedmineTintIssues::Patches::IssuePatch::InstanceMethods
    assert_operator Issue.ancestors.index(mod), :<, Issue.ancestors.index(Issue)
    other = Module.new { def css_classes(user = User.current); super(user) << ' other-plugin'; end }
    Issue.prepend(other)
    tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days') do
      assert_includes classes, 'other-plugin'
      assert_includes classes, 'current'
    end
  end

  test "css_classes needs a constant number of queries and setting reads, whatever the number of issues" do
    counter = Module.new do
      attr_accessor :tint_reads
      def [](name)
        self.tint_reads = tint_reads.to_i + 1 if name == 'plugin_redmine_tint_issues'
        super
      end
    end
    Setting.singleton_class.prepend(counter)
    sql = []
    sub = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      sql << payload[:sql] if payload[:sql] =~ /enabled_modules|"settings"|`settings`/
    end
    measure = lambda do |n|
      issues = Array.new(n) { Issue.find(1) } # each with a project of its own
      result = nil
      tint('current_issue_age' => '1', 'current_issue_age_epoch' => 'days', 'due_since' => '3', 'due_since_epoch' => 'days') do
        sql.clear
        Setting.tint_reads = 0
        issues.each(&:css_classes)
        result = [sql.size, Setting.tint_reads]
      end
      result
    end
    measure.call(2) # warm-up: one-time lazy work of this or other installed plugins is not per issue
    few, many = measure.call(5), measure.call(25)
    assert_equal few, many, "5 issues #{few.inspect}, 25 issues #{many.inspect} (queries, setting reads)"
    assert_operator many[0], :<=, 2 # the modules of all projects and the plugin settings, once
    assert_operator many[1], :<=, 1
  ensure
    ActiveSupport::Notifications.unsubscribe(sub)
  end
end
