# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

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
  #
  def bias_slider(tag, options = {})    
    bias = ((tag.is_a?(Tag) ? tag.bias : 1.0) or 1.0)   
    # Don't let it go over 1.3
    max_bias_value = [bias, 1.3].max     
    slider_disabled = options[:disabled] ? true : false
    prefix = tag.dom_id('slider')
    variable = "#{prefix}_var"
        
    js = "var #{variable} = new BiasSlider('#{prefix}_handle', '#{prefix}_track', {" + 
              "onChange: function(newBias, slider) {slider.sendUpdate(newBias, slider.options.tag_id);}," +
              "tag_id: #{tag.id}," +
  						"disabled: #{slider_disabled}," +
  						"range: $R(0.9, #{max_bias_value})," +
  						"values: $R(90,#{max_bias_value * 100}).map(function(i) {return i / 100;})," +
  						"sliderValue: #{bias}" +
  				"});\n"
  	
  	# Set the position of the slider markers
  	[0.9, 1.0, 1.1, 1.2, 1.3].each do |v|
  	  js << "$('#{prefix}_#{v.to_s.sub('.', '_')}').setStyle({left: #{variable}.translateToPx(#{v})});\n"
  	  
  	  unless slider_disabled
  		  js << "Event.observe($('#{prefix}_#{v.to_s.sub('.', '_')}'), 'mousedown', function(){#{variable}.setValue(#{v})});\n"
		  end
	  end
    
    if slider_disabled
      js << "$('#{prefix}_track').addClassName('disabled');\n"
    end
    
    bias_slider_html(prefix) + javascript_tag(js)
  end
  
  private
  def bias_slider_html(prefix)
    content_tag('div', 
        content_tag('div', '', :id => "#{prefix}_0_9", :class => 'bias_marker', :title => "Very Negative") +
        content_tag('div', '', :id => "#{prefix}_1_0", :class => 'bias_marker neutral', :title => "Neutral") +
        content_tag('div', '', :id => "#{prefix}_1_1", :class => 'bias_marker', :title => "Slightly Positive") +
        content_tag('div', '', :id => "#{prefix}_1_2", :class => 'bias_marker', :title => "Strongly Positive") +
        content_tag('div', '', :id => "#{prefix}_1_3", :class => 'bias_marker', :title => "Very Strongly Positive") +
        content_tag('div','', :id => "#{prefix}_handle", :class => 'slider_handle', :title => "Drag to set the sensitvity of the classifier."),
     :id => "#{prefix}_track", :class => 'slider_track')
  end
end