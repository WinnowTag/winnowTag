require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test/unit'

$asset_packages_yml = YAML.load_file("#{RAILS_ROOT}/vendor/plugins/asset_packager/test/asset_packages.yml")
$asset_base_path = "#{RAILS_ROOT}/vendor/plugins/asset_packager/test/assets"

class AssetPackagerTest < Test::Unit::TestCase
  include Synthesis
  
  def test_find_by_type
    js_asset_packages = Synthesis::AssetPackage.find_by_type("javascripts")
    assert_equal 2, js_asset_packages.length
    assert_equal "base", js_asset_packages[0].target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], js_asset_packages[0].sources
  end
  
  def test_find_by_target
    package = Synthesis::AssetPackage.find_by_target("javascripts", "base")
    assert_equal "base", package.target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], package.sources
  end
  
  def test_find_by_source
    package = Synthesis::AssetPackage.find_by_source("javascripts", "controls")
    assert_equal "base", package.target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], package.sources
  end
  
  def test_delete_and_build
    Synthesis::AssetPackage.delete_all
    js_package_names = Dir.new("#{$asset_base_path}/javascripts").entries.delete_if { |x| ! (x =~ /\A\w+_\d+.js/) }
    css_package_names = Dir.new("#{$asset_base_path}/stylesheets").entries.delete_if { |x| ! (x =~ /\A\w+_\d+.css/) }
    
    assert_equal 0, js_package_names.length
    assert_equal 0, css_package_names.length

    Synthesis::AssetPackage.build_all
    js_package_names = Dir.new("#{$asset_base_path}/javascripts").entries.delete_if { |x| ! (x =~ /\A\w+_\d+.js/) }.sort
    css_package_names = Dir.new("#{$asset_base_path}/stylesheets").entries.delete_if { |x| ! (x =~ /\A\w+_\d+.css/) }.sort
    
    assert_equal 2, js_package_names.length
    assert_equal 2, css_package_names.length
    assert js_package_names[0].match(/\Abase_\d+.js\z/)
    assert js_package_names[1].match(/\Asecondary_\d+.js\z/)
    assert css_package_names[0].match(/\Abase_\d+.css\z/)
    assert css_package_names[1].match(/\Asecondary_\d+.css\z/)
  end
  
  def test_js_names_from_sources
    package_names = Synthesis::AssetPackage.targets_from_sources("javascripts", ["prototype", "effects", "noexist1", "controls", "foo", "noexist2"])
    assert_equal 4, package_names.length
    assert package_names[0].match(/\Abase_\d+\z/)
    assert_equal package_names[1], "noexist1"
    assert package_names[2].match(/\Asecondary_\d+\z/)
    assert_equal package_names[3], "noexist2"
  end
  
  def test_css_names_from_sources
    package_names = Synthesis::AssetPackage.targets_from_sources("stylesheets", ["header", "screen", "noexist1", "foo", "noexist2"])
    assert_equal 4, package_names.length
    assert package_names[0].match(/\Abase_\d+\z/)
    assert_equal package_names[1], "noexist1"
    assert package_names[2].match(/\Asecondary_\d+\z/)
    assert_equal package_names[3], "noexist2"
  end
  
end
