# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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