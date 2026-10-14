# encoding: utf-8

module RedmineTintIssues
  # Per request (and per job or test) memo of what Issue#css_classes needs for every issue
  # rendered: the plugin settings, the thresholds calculated from them and the ids of the
  # projects with the module. Reset by Rails around every request, job and test.
  class Current < ActiveSupport::CurrentAttributes
    attribute :settings, :dues_and_ages, :project_ids

    def self.settings
      super || (self.settings = Setting['plugin_redmine_tint_issues'].to_h)
    end

    def self.module_enabled?(project_id)
      self.project_ids ||= EnabledModule.where(:name => 'redmine_tint_issues').pluck(:project_id).to_set
      project_ids.include?(project_id)
    end
  end
end

# a project switching the module on or off is seen by the next css_classes of the same request
EnabledModule.class_eval do
  after_save    { RedmineTintIssues::Current.project_ids = nil }
  after_destroy { RedmineTintIssues::Current.project_ids = nil }
end
