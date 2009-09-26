# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module BiasSliderHelper
  # Creates a slider for setting the sensitivity of the classifier for a specific tag. 
  # The slider will be disabled if the tag is not owned by the current user.
  def bias_slider_html(tag)
    content_tag 'div', 
      content_tag('div', 
        content_tag('div', '', :class => '0_9 bias_marker zero_point_nine', :title => t("winnow.tags.main.slider_tooltips.first_marker"))  +
        content_tag('div', '', :class => '1_0 bias_marker one_point_zero',  :title => t("winnow.tags.main.slider_tooltips.second_marker")) +
        content_tag('div', '', :class => '1_1 bias_marker one_point_one',   :title => t("winnow.tags.main.slider_tooltips.third_marker"))  +
        content_tag('div', '', :class => '1_2 bias_marker one_point_two',   :title => t("winnow.tags.main.slider_tooltips.fourth_marker")) +
        content_tag('div', '', :class => '1_3 bias_marker one_point_three', :title => t("winnow.tags.main.slider_tooltips.fifth_marker"))  +
        content_tag('div', '', :class => 'slider_handle',                   :title => t("winnow.tags.main.slider_tooltips.handle")),
        :class => 'slider_track'), 
      :class => "slider", :bias => tag.bias, :disabled => tag.user_id != current_user.id, :href => tag_path(tag), :method => :put
  end
end