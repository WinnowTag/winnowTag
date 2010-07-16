# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper
  # Makes sure the content is valid HTML, textilzes it to transform any 
  # markup to HTML, and finally sanitizes it to remove dangerous HTML.
  def sth(content)
    sanitize(textilize(Hpricot.parse(content.to_s).to_s))
  end
  
  # Makes sure the content is valid HTML, and finally sanitizes it to 
  # remove dangerous HTML.
  def sh(content)
    sanitize(Hpricot.parse(content.to_s).to_s)
  end
  
  # Returns the class used to style the selected main nagivation tab if the 
  # current controller/action match.
  def tab_selected(controller, action = nil)
    "selected" if controller_name == controller and (action.nil? or action_name == action)
  end
  
  # Generates the javascript to display the flash messages in our javascript
  # messages system.
  def show_flash_messages
    javascript = [:notice, :warning, :error].map do |name|
      "Message.add('#{name}', #{flash[name].to_json});" unless flash[name].blank?
    end.join
    
    javascript << Message.unread(current_user).for(current_user).map do |message|
      message.read_by!(current_user)
      
      if message.user
        "Message.add('error', #{h(message.body).to_json});"
      else
        "Message.add('warning', #{sth(message.body).to_json});"
      end
    end.join if current_user
    
    javascript_tag(javascript) unless javascript.blank?
  end
  
  # Generates the link to control the direction of the sorting.
  def direction_link
    link_to_function "<span class='asc' title='#{t("winnow.sort_direction.ascending_tooltip")}'>#{t("winnow.sort_direction.ascending")}</span><span class='desc' title='#{t("winnow.sort_direction.descending_tooltip")}'>#{t("winnow.sort_direction.descending")}</span>", "", :id => "direction"
  end
  
  # Helper to check if the current user is an admin.
  def is_admin?
    if @is_admin.nil?
      @is_admin = (current_user.has_role?('admin') == true)
    end
    
    @is_admin
  end
  
  # Custom version of the +in_place_editor+ helper to expose additional features
  # from the javascript library.
  def in_place_editor(field_id, options = {})
    function =  "new Ajax.InPlaceEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['cancelControl'] = options[:cancel_control].inspect if options.has_key?(:cancel_control)
    js_options['okControl'] = options[:save_control].inspect if options.has_key?(:save_control)
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['externalControlOnly'] = "true" if options[:external_control_only]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['htmlResponse'] = options[:html_response] if options.key?(:html_response)
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['paramName'] = %('#{options[:param_name]}') if options[:param_name]
    js_options['method'] = %('#{options[:method]}') if options[:method]
    js_options['onEnterHover'] = %('#{options[:on_enter_hover]}') if options[:on_enter_hover]
    js_options['onLeaveHover'] = %('#{options[:on_leave_hover]}') if options[:on_leave_hover]
    js_options['onComplete'] = %('#{options[:on_complete]}') if options[:on_complete]
    js_options['onEnterEditMode'] = options[:on_enter_edit_mode] if options[:on_enter_edit_mode]
    js_options['onLeaveEditMode'] = options[:on_leave_edit_mode] if options[:on_leave_edit_mode]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
    
    function << ')'

    javascript_tag(function)
  end

  # Generates the control to mark a tag a globally excluded/not globally excluded.
  def globally_exclude_tag_check_box(tag)
    url = globally_exclude_tag_path(tag)
    
    check_box_tag dom_id(tag, "globally_exclude"), "1", current_user.globally_excluded?(tag),
      :id => dom_id(tag, 'globally_exclude'), :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}"),
      :title => t("winnow.general.globally_exclude_tag_tooltip")
  end

  # Generates the control to mark a feed a globally excluded/not globally excluded.
  def globally_exclude_feed_check_box(feed)
    url = if feed.is_a?(Feed)
      globally_exclude_feed_path(feed)
    elsif feed.is_a?(Remote::Feed)
      globally_exclude_feed_path(:id => feed.id)
    end

    check_box_tag dom_id(feed, "globally_exclude"), "1", current_user.globally_excluded?(feed),
      :id => dom_id(feed, 'globally_exclude'), :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}"),
      :title => t("winnow.general.globally_exclude_feed_tooltip")
  end

  # Generates the control to mark a tag subscribed/unsbscribed
  def subscribe_check_box(tag)
    check_box_tag dom_id(tag, "subscribe"), "1", current_user.subscribed?(tag), :id => dom_id(tag, 'subscribe'), 
      :onclick => remote_function(:url => subscribe_tag_path(tag), :method => :put, :with => "{subscribe: this.checked}"),
      :title => t("winnow.tags.main.subscribe_tooltip")
  end

  # Generates the controls to filter the list of tags.
  def tag_filter_controls(tags, subscribed_tags, options = {})
    # TODO: This should be elsewhere, and a method extending a class, and have its own test
    def duplicates(a)
      a.inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
    end

    duplicate_names = duplicates(subscribed_tags.collect() { |t| t.name });
    options.merge!(:duplicate_names => duplicate_names) if (!duplicate_names.empty?);

    tags.map { |tag| tag_filter_control(tag, options) }.join
  end

  # Generates the HTML displaying a tag name with an appended span containing the user name if the tag name is not unique.
  # The user "staff" is never displayed.
  def tag_name_uniqued(tag, options = {})
    if (options[:duplicate_names])
      duplicate_names = options[:duplicate_names]
    else
      duplicate_names = {}
    end

    if ((tag.user_id != current_user.id) && duplicate_names.include?(tag.name))
      return(h(tag.name) + '<span class="tag_name_uniqued">:' + User.find_by_id(tag.user_id).login) + "</span>"
    else
      return(tag.name)
    end

    # (User.find_by_login("lelan").tag_subscriptions.collect() { |a| Tag.find_by_id(a.tag_id) } + User.find_by_login("lelan").tags).collect() { |a| a.name == "maps" ? a : nil }.compact
  end

  # Generates an individual control to filter the list of tags.
  # See ApplicationHelper#tag_filter_controls.
  def tag_filter_control(tag, options = {})
    class_names = [dom_id(tag), "tag"]
    class_names << "subscribed" if tag.user_id != current_user.id
    class_names << "public" if tag.public? && tag.user_id == current_user.id

    content_tag(:li, 
                content_tag(:div, "", :class => "context_menu_button", :'tag-id' => tag.id) +
                content_tag(:span, 
                            content_tag(:span, 
                                        tag_name_uniqued(tag, options),
                                        :class => "name", 
                                        :id => dom_id(tag, "name"), 
                                        :"data-sort" => tag.sort_name),
                            :class => "filter"),
                :id => dom_id(tag), 
                :class => class_names.join(" "),
                :name => tag.name,
                :pos_count => tag.positive_count,
                :neg_count => tag.negative_count,
                :item_count => tag.feed_items_count,
                :title => tag_tooltip(tag))
    
  end
  
  # Generates a tooltip for the tag filters in the feed items sidebar. 
  # The tooltip contains the training information for the tag.
  def tag_tooltip(tag)
    if tag.user_id == current_user.id
      if tag.public
        t("winnow.items.sidebar.published_tag_tooltip", :name => h(tag.name), :positive => tag.positive_count, :negative => tag.negative_count, :automatic => tag.classifier_count)
      else
        t("winnow.items.sidebar.tag_tooltip", :name => h(tag.name), :positive => tag.positive_count, :negative => tag.negative_count, :automatic => tag.classifier_count)
      end
    else
      t("winnow.items.sidebar.subscribed_tag_tooltip", :name => h(tag.name), :login => h(tag.user.login), :positive => tag.positive_count, :negative => tag.negative_count, :automatic => tag.classifier_count)
    end
  end
  
  # Provide the path to use for the help link on the current page
  def help_path
    if controller_name && action_name
      t("winnow.help_links." + controller_name + "." + action_name)
    else
      t("winnow.help_links.default")
    end
  end

  # Generates the classes that should exist on a tag. These are used to properly style the tag.
  def tag_classes(tag)
    classes = [dom_id(tag)]
    
    classes << "public" if tag.public?
    
    if current_user.globally_excluded?(tag)
      classes << "globally_excluded"
    elsif current_user.subscribed?(tag)
      classes << "subscribed"
    elsif (current_user.id == tag.user_id) && tag.public
      classes << "published"
    end
    classes.join(" ")
  end

  # Generates the classes that should exist on a feed. These are used to properly style the feed.
  def feed_classes(feed)
    if current_user.globally_excluded?(feed)
      "globally_excluded"
    end
  end

  # Generates the state text that should be shown for a tag.
  def tag_state(tag)
    if current_user.globally_excluded?(tag)
      t("winnow.tags.general.globally_excluded")
    elsif current_user.subscribed?(tag)
      t("winnow.tags.general.subscribed")
    elsif (current_user.id == tag.user_id) && tag.public
      t("winnow.tags.general.public")
    end
  end

  # Generates the tag state tooltip that should exist on the state label (subscribed/blocked/blank) of a tag.
  def tag_state_tooltip(tag)
    if current_user.globally_excluded?(tag)
      t("winnow.tags.general.globally_excluded_tooltip")
    elsif current_user.subscribed?(tag)
      t("winnow.tags.general.subscribed_tooltip")
    elsif (current_user.id == tag.user_id) && tag.public
      t("winnow.tags.general.public_tooltip")
    end
  end

  # Generates a rounded button with a javascript action.
  def rounded_button_function(name, function, html_options = {}, &block)
    (html_options[:class] ||= "") << " button"
    if icon = html_options.delete(:icon)
      link_to_function(content_tag(:span, name, :class => "icon #{icon}"), function, html_options, &block)
    else
      link_to_function(name, function, html_options, &block)
    end
  end

  # Generates a rounded button with a link action.
  def rounded_button_link(name, options = {}, html_options = {})
    (html_options[:class] ||= "") << " button"
    if icon = html_options.delete(:icon)
      link_to(content_tag(:span, name, :class => "icon #{icon}"), options, html_options)
    else
      link_to(name, options, html_options)
    end
  end
  
  def safari?
    # --- Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9
    # --- Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9.1
    request.env["HTTP_USER_AGENT"] =~ /Safari/
  end
  
  def chrome?
    # --- Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/530.5 (KHTML, like Gecko) Chrome/2.0.172.43 Safari/530.5
    request.env["HTTP_USER_AGENT"] =~ /Chrome/
  end
  
  def firefox?
    # --- Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1) Gecko/20090624 Firefox/3.5
    # --- Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2 (.NET CLR 3.5.30729)
    request.env["HTTP_USER_AGENT"] =~ /Firefox/
  end
  
  def opera?
    # --- Opera/9.64 (Macintosh; Intel Mac OS X; U; en) Presto/2.1.1
    # --- Opera/9.64 (Windows NT 5.1; U; en) Presto/2.1.1
    request.env["HTTP_USER_AGENT"] =~ /Opera/
  end
  
  def ie6?
    # --- Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)
    request.env["HTTP_USER_AGENT"] =~ /MSIE 6/
  end
  
  def ie7?
    # --- Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)
    request.env["HTTP_USER_AGENT"] =~ /MSIE 7/
  end
  
  def ie8?
    # --- Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)
    request.env["HTTP_USER_AGENT"] =~ /MSIE 8/
  end

  # Returns the proper bookmarklet installation instructions based on the 
  # users browser.
  def bookmarklet_installation_instructions
    if chrome? # this comes first, because safari? will return true when the browser is really chrome
      # drag to bookmarks bar
      t("winnow.feeds.header.bookmarklet_installation_instructions.chrome")
    elsif safari?
      # drag to bookmarks bar
      t("winnow.feeds.header.bookmarklet_installation_instructions.safari")
    elsif firefox?
      # drag to bookmarks toolbar, right click + Bookmark This Link + Folder - Bookmarks Toolbar
      t("winnow.feeds.header.bookmarklet_installation_instructions.firefox")
    elsif opera?
      # drag to personal bar, right click + "Bookmark Link..." + Details - check Show on Personal Bar
      t("winnow.feeds.header.bookmarklet_installation_instructions.opera")
    elsif ie6?
      # right click + "Add to Favorites..." + Yes to Security Alert + Create in - Links
      t("winnow.feeds.header.bookmarklet_installation_instructions.ie6")
    elsif ie7?
      # right click + "Add to Favorites..." + Yes to Security Alert + Create in - Favorites Bar
      t("winnow.feeds.header.bookmarklet_installation_instructions.ie7")
    elsif ie8?
      # right click + "Add to Favorites..." + Yes to Security Alert + Create in - Links
      t("winnow.feeds.header.bookmarklet_installation_instructions.ie8")
    end
  end
end
