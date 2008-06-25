# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module BiasSliderHelper
  # Creates a Bias slider for setting the sensitivity of the classifier
  #
  # === Parameters
  #
  # <tt>:tag</tt>:: The tag to show the bias for. Can be nil or :default too.
  # <tt>:var</tt>:: A javascript variable to assign the slider to.
  # <tt>:prefix</tt>:: A prefix for all dom ids for created HTML elements (see +bias_slider_html+).
  #
  # When tag is nil, a disabled slider is shown with the default
  # bias. When tag is :default the default bias will be show, but it will be editable.
  # When tag is a user tag the bias for that tag will be shown and it will be editable.
  def bias_slider(tag, options = {})
    bias_slider_html(tag) + javascript_tag(bias_slider_js(tag, options))
  end
  
  def bias_slider_js(tag, options = {})    
    bias = tag.bias || 1.0
    # Don't let it go over 1.3
    max_bias_value = [bias, 1.3].max     
    slider_disabled = options[:disabled] ? true : false
    prefix = dom_id(tag, 'slider')
        
    js  = "if(!BiasSlider.sliders.#{prefix}) {"
    js << "BiasSlider.sliders.#{prefix} = new BiasSlider('#{prefix}_handle', '#{prefix}_track', {" + 
              "onChange: function(newBias, slider) {slider.sendUpdate(newBias, slider.options.tag_id);}," +
              "tag_id: #{tag.id}," +
  						"disabled: #{slider_disabled}," +
  						"range: $R(0.9, #{max_bias_value})," +
  						"sliderValue: #{bias}" +
  				"});"
  	js << "}"
  end
  
  def bias_slider_html(tag)
    prefix = dom_id(tag, 'slider')
    content_tag 'div', 
      content_tag('div', 
        content_tag('div', '', :id => "#{prefix}_0_9",    :class => '0_9 bias_marker',         :title => _(:first_slider_marker))  +
        content_tag('div', '', :id => "#{prefix}_1_0",    :class => '1_0 bias_marker neutral', :title => _(:second_slider_marker)) +
        content_tag('div', '', :id => "#{prefix}_1_1",    :class => '1_1 bias_marker',         :title => _(:third_slider_marker))  +
        content_tag('div', '', :id => "#{prefix}_1_2",    :class => '1_2 bias_marker',         :title => _(:fourth_slider_marker)) +
        content_tag('div', '', :id => "#{prefix}_1_3",    :class => '1_3 bias_marker',         :title => _(:fifth_slider_marker))  +
        content_tag('div', '', :id => "#{prefix}_handle", :class => 'slider_handle',           :title => _(:slider_handle_tooltip)),
        :id => "#{prefix}_track", :class => 'slider_track'), 
      :class => "slider"
  end
end