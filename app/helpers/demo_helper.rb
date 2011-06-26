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


module DemoHelper
  # The +feed_control_for+ generates the control to show/hide the feed information on a feed item/
  # This is displayed in the collapsed view of a feed item.
  def feed_title_for(feed_item)
    t("winnow.items.main.feed_metadata", :feed_title => content_tag(:span, h(feed_item.feed_title), :class => "feed_title"))
  end
  
  def current_tag_training(feed_item)
    if feed_item.tagged_type.nil?
      ""
    elsif feed_item.tagged_type.to_i == 1
      "positive"
    elsif feed_item.tagged_type.to_i == 0
      "negative"
    else
      ""
    end
  end

  def demo_tag_controls 
    @user.tags_for_sidebar.map do |tag|
      content_tag("li", tag.name, :id => dom_id(tag), 
                                  :class => "tag", 
                                  :title => tag.description, 
                                  :name => tag.name,
                                  :pos_count => tag.positive_count,
                                  :neg_count => tag.negative_count,
                                  :item_count => tag.feed_items_count)
    end.join
  end
end
