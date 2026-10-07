# encoding: utf-8
require File.expand_path('../../../../../test/test_helper', __FILE__)

class TintIssuesSettingsTest < Redmine::ControllerTest
  tests SettingsController
  fixtures :users, :email_addresses, :roles

  def setup
    User.current = nil
    @request.session[:user_id] = 1
  end

  test "settings page shows every tint field, the picker images and the help icons" do
    get :plugin, :params => {:id => 'redmine_tint_issues'}
    assert_response :success
    %w(current old older veryold ancient).each { |a| assert_select "input[name=?]", "settings[#{a}_issue_age_color]" }
    %w(due_since moredue_since verydue_since).each { |a| assert_select "select[name=?]", "settings[#{a}_epoch]" }
    assert_select "input[name='settings[age_by_creation_date]'][type=radio]", 2
    assert_select 'a[onclick*="help_settings_age_by_creation_date"]'
    assert_select 'script', :text => /jscolor\.imageUrls = \{.*hs\.png/m
    assert_no_match(/redmine_tint_issues\.css/, response.body)
  end

  test "settings page needs an administrator" do
    @request.session[:user_id] = 2
    get :plugin, :params => {:id => 'redmine_tint_issues'}
    assert_response :forbidden
  end

  test "settings are saved" do
    post :plugin, :params => {:id => 'redmine_tint_issues', :settings => {
      :current_issue_age => '2', :current_issue_age_epoch => 'days', :current_issue_age_color => '#99ff99',
      :age_by_creation_date => '0'}}
    assert_redirected_to '/settings/plugin/redmine_tint_issues'
    settings = Setting['plugin_redmine_tint_issues']
    assert_equal '2', settings['current_issue_age']
    assert_equal '#99ff99', settings['current_issue_age_color']
    assert_equal '0', settings['age_by_creation_date']
  end
end
