# encoding: utf-8
require File.expand_path('../../../../../test/test_helper', __FILE__)

class ApplicationHelperTintTest < Redmine::HelperTest
  include ApplicationHelper

  test "contrast color is orange on a light and lightyellow on a dark background" do
    assert_equal 'orange',      rti_contrast_css_color('#ffffff')
    assert_equal 'lightyellow', rti_contrast_css_color('#000000')
  end

  test "contrast color falls back to black without or with an invalid color" do
    assert_equal 'black', rti_contrast_css_color(nil)
    assert_equal 'black', rti_contrast_css_color('zz')
  end

  test "lighten color" do
    assert_equal '#ffffff', rti_lighten_css_color(nil)
    assert_equal '#999999', rti_lighten_css_color('#000000', 0.6)
    assert_equal '#0d0d0d', rti_lighten_css_color('#000000', 0.05)
    assert_equal '#ffffff', rti_lighten_css_color('#ffffff')
  end

  test "help link toggles its target and carries the help label" do
    html = rti_help_link('help_x')
    assert_select_in html, 'a[href="#"][onclick*="#help_x"][title=?]', ::I18n.t(:label_help)
    assert_select_in html, 'a svg' if respond_to?(:sprite_icon)
  end

  test "jscolor images are served by their digested asset path" do
    images = rti_jscolor_images
    if Redmine::VERSION::MAJOR >= 6
      assert_equal %w(arrow.gif cross.gif hs.png hv.png), images.keys.sort
      images.each_value { |url| assert_match %r{\A/assets/plugin_assets/redmine_tint_issues/\w+-[0-9a-f]+\.(png|gif)\z}, url }
    else
      assert_equal({}, images)
    end
  end
end
