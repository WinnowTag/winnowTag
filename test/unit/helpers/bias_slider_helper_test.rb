# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../test_helper'

class BiasSliderHelperTest < HelperTestCase
  fixtures :users, :bayes_classifiers
  attr_reader :current_user
  include BiasSliderHelper
  
  def setup
    super
    @current_user = User.find(1)
  end
  
  def test_bias_slider_html
    @response.body = bias_slider_html('test')
    
    assert_select('div#test_track.slider_track', 1, "Slider track not created")
    assert_select('div#test_track div#test_handle.slider_handle', 1, "Slider handle not created")
    assert_select('div#test_track div.bias_marker', 5, "Bias Markers not created")
    assert_select('div#test_track div.bias_marker.neutral', 1, "Neutral Bias Marker not created")
  end
  
  def test_bias_slider_with_default_prefix
    @response.body = bias_slider()
    assert_select('div#bias_slider_track.slider_track', 1, "Slider track not created: #{@response.body}")
    assert_match(/new BiasSlider\('bias_slider_handle', 'bias_slider_track'/, @response.body)
  end
  
  def test_bias_slider_creates_track_and_passes_it_to_js
    @response.body = bias_slider(:prefix => 'test_bias', :var => 'test_bias')
    assert_select('div#test_bias_track.slider_track', 1, "Slider track not created: #{@response.body}")
    assert_match(/var test_bias = new BiasSlider\('test_bias_handle', 'test_bias_track'/, @response.body)
  end
  
  def test_bias_slider_using_global_variable
    @response.body = bias_slider(:prefix => 'test_bias', :global => 'test_bias')
    assert_select('div#test_bias_track.slider_track', 1, "Slider track not created: #{@response.body}")
    assert_match(/\ntest_bias = new BiasSlider\('test_bias_handle', 'test_bias_track'/, @response.body)
  end
  
  def test_bias_slider_disabled_when_tag_is_nil
    @response.body = bias_slider()
    assert_match(/disabled: true/, @response.body)
    assert_match(/\('bias_slider_track'\)\.addClassName\('disabled'\)/, @response.body)
  end
  
  def test_bias_slider_not_disabled_when_tag_is_default
    @response.body = bias_slider(:tag => :default)
    assert_match(/disabled: false/, @response.body)
    assert_no_match(/\('bias_slider_track'\)\.addClassName\('disabled'\)/, @response.body)
  end
  
  def test_bias_slider_sets_position_of_markers
    @response.body = bias_slider(:prefix => 'test', :var => 'test_slider')
    exp = Regexp.new(Regexp.escape("$('test_0_9').setStyle({left: test_slider.translateToPx(0.9)})"))
    assert_match(exp, @response.body)
  end
  
  def test_bias_slider_observes_clicks_on_markers
    @response.body = bias_slider(:prefix => 'test', :var => 'test_slider', :tag => Tag(current_user, 'tag'))
    exp = Regexp.new(Regexp.escape("Event.observe($('test_0_9'), 'mousedown',"))
    assert_match(exp, @response.body)
  end
  
  def test_bias_slider_add_on_change_handler
    @response.body = bias_slider(:change => "alert('slider changed!)")
    exp = Regexp.new(Regexp.escape("onChange: function(value, slider){\nalert('slider changed!)\n},"))
    assert_match(exp, @response.body)
  end
end