# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feedbacks/_header_controls.html.erb' do
  def render_it
    render :partial => '/feedbacks/header_controls.html.erb'
  end
  
  it "needs specs"
end

# <ul class="control_bar">
#   <li class="order">
#     Sort:
#     <%= link_to_function "User", "itemBrowser.setOrder('user')", :id => "order_user" %>, 
#     <%= link_to_function "Date", "itemBrowser.setOrder('date')", :id => "order_date" %>
#   </li>    
# </ul>
# 
# <% form_tag feedbacks_path, :method => :get, :onsubmit => "itemBrowser.addFilters({text_filter: $F('text_filter')}); return false;" do -%>
#   <%= search_field_tag "text_filter", params[:text_filter], :placeholder => "Search Feedback...", :clear => { :onclick => "itemBrowser.addFilters({text_filter: null});" } %>
# <% end -%>