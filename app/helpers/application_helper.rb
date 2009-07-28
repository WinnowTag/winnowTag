# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper  
  include DateHelper

  def sth(content)
    sanitize(textilize(Hpricot.parse(content.to_s).to_s))
  end
  
  def sh(content)
    sanitize(Hpricot.parse(content.to_s).to_s)
  end
  
  def tab_selected(controller, action = nil)
    "selected" if controller_name == controller and (action.nil? or action_name == action)
  end
  
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
  
  def direction_link
    link_to_function "<span class='asc' title='#{t("winnow.sort_direction.ascending_tooltip")}'>#{t("winnow.sort_direction.ascending")}</span><span class='desc' title='#{t("winnow.sort_direction.descending_tooltip")}'>#{t("winnow.sort_direction.descending")}</span>", "", :id => "direction"
  end
  
  def is_admin?
    if @is_admin.nil?
      @is_admin = (current_user.has_role?('admin') == true)
    end
    
    @is_admin
  end
  
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
  
  def open_folder?(folder)
    cookies[dom_id(folder)] =~ /true/i
  end
  
  def section_open?(id)
    cookies[id] =~ /true/i
  end
  
  def globally_exclude_check_box(tag_or_feed)
    url = if tag_or_feed.is_a?(Tag)
      globally_exclude_tag_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      globally_exclude_feed_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Remote::Feed)
      globally_exclude_feed_path(:id => tag_or_feed.id)
    end
    
    check_box_tag dom_id(tag_or_feed, "globally_exclude"), "1", current_user.globally_excluded?(tag_or_feed),
      :id => dom_id(tag_or_feed, 'globally_exclude'), :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}"),
      :title => t("winnow.general.globally_exclude_tooltip")
  end

  def subscribe_check_box(tag)
    check_box_tag dom_id(tag, "subscribe"), "1", current_user.subscribed?(tag), :id => dom_id(tag, 'subscribe'), 
      :onclick => remote_function(:url => subscribe_tag_path(tag), :method => :put, :with => "{subscribe: this.checked}"),
      :title => t("winnow.tags.main.subscribe_tooltip")
  end
  
  def feed_filter_controls(feeds, options = {})
    content =  feeds.map { |feed| feed_filter_control(feed, options) }.join
    if options[:add]
      begin
        uri = URI.parse(options[:auto_complete])
        if uri.scheme.present?
          content << content_tag(:li, t("winnow.items.sidebar.create_feed", :feed => h(uri.to_s)), :id => "add_new_feed", :url => uri.to_s)
        end
      rescue URI::Error # don't add the "Create Feed" option if the URI is not valid
      end
    end
    content_tag :ul, content, options.delete(:ul_options) || {}
  end
  
  def feed_filter_control(feed, options = {})   
    url      = case options[:remove]
      when :subscription then subscribe_feed_path(feed, :subscribe => "false")
      when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(feed))
    end
    function = case options[:remove]
      when :subscription then "itemBrowser.removeFilters({feed_ids: '#{feed.id}'});"
    end
    
    class_names = [dom_id(feed), "clearfix", "feed"]
    class_names << "draggable" if options[:draggable]

    html = link_to_function("Remove", "#{function}$(this).up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => url, :method => :put)}", :class => "remove")
    html = content_tag(:span, html, :class => "actions")

    html << link_to_function(h(feed.title), "", :class => "name")
    
    html =  content_tag(:span, html, :class => "filter")
    html << content_tag(:span, highlight(h(feed.title), h(options[:auto_complete]), '<span class="highlight">\1</span>'), :class => "auto_complete_name") if options[:auto_complete]

    html =  content_tag(:li, html, :id => dom_id(feed), :class => class_names.join(" "), :subscribe_url => subscribe_feed_path(feed, :subscribe => true))
    html
  end
  
  def tag_filter_controls(tags, options = {})
    content =  tags.map { |tag| tag_filter_control(tag, options) }.join
    content_tag :ul, content, options.delete(:ul_options) || {}
  end
  
  # Complex method in that it builds HTML, JS, and CSS using strings. At least it is
  # covered by several examples in application_helper_spec
  def tag_filter_control(tag, options = {})
    if options[:remove] == :subscription && current_user.id == tag.user_id
      options = options.except(:remove)
      options[:remove] = :sidebar
    end
    
    remove_url = case options[:remove]
      when :subscription           then unsubscribe_tag_path(tag)
      when :sidebar                then sidebar_tag_path(tag, :sidebar => "false")
      when Folder                  then remove_item_folder_path(options[:remove], :item_id => dom_id(tag))
    end
    
    subscribe_url = case options[:remove]
      when :subscription           then subscribe_tag_path(tag, :subscribe => true)
      when :sidebar                then sidebar_tag_path(tag, :sidebar => true)
    end
    
    function = case options[:remove]
      when :subscription, :sidebar then "itemBrowser.removeFilters({tag_ids: '#{tag.id}'});"
    end
    
    class_names = [dom_id(tag), "clearfix", "tag"]
    class_names << "public" if tag.user_id != current_user.id
    class_names << "draggable" if options[:draggable]

    html  = ""
    if options[:editable] && current_user.id == tag.user_id
      rename_function = "var new_tag_name = prompt('Tag Name:', $(this).up('.tag').down('.name').innerHTML.unescapeHTML()); if(new_tag_name) { #{remote_function(:url => tag_path(tag), :method => :put, :with => "'tag[name]=' + new_tag_name")} }"
      html << link_to_function("Rename", rename_function, :class => "edit")
    end
    html << link_to_function("Remove", "#{function}$(this).up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => remove_url, :method => :put)}", :class => "remove")
    html  = content_tag(:span, html, :class => "actions")

    html << link_to_function(h(tag.name), "", :class => "name", :id => dom_id(tag, "name"))

    html =  content_tag(:span, html, :class => "filter")
    html << content_tag(:span, highlight(h(tag.name), h(options[:auto_complete]), '<span class="highlight">\1</span>'), :class => "auto_complete_name") if options[:auto_complete]
    
    html =  content_tag(:li, html, :id => dom_id(tag), :class => class_names.join(" "), :subscribe_url => subscribe_url, :title => tag_tooltip(tag))
    html
  end
  
  def tag_tooltip(tag)
    if tag.user_id == current_user.id 
      t("winnow.items.sidebar.tag_tooltip", :positive => tag.positive_count, :negative => tag.negative_count, :automatic => tag.classifier_count)
    else
      t("winnow.items.sidebar.public_tag_tooltip", :login => h(tag.user.login), :positive => tag.positive_count, :negative => tag.negative_count, :automatic => tag.classifier_count)
    end
  end
  
  def help_path
    setting = YAML.load(Setting.find_or_initialize_by_name("Help").value.to_s)
    if setting && setting[controller_name] && setting[controller_name][action_name]
      setting[controller_name][action_name]
    elsif setting && setting["default"]
      setting['default']
    end
  rescue ArgumentError # Swallow malformed yaml exceptions
  end
  
  def tag_classes(tag)
    classes = [dom_id(tag)]
    
    classes << "public" if tag.public?
    
    if current_user.globally_excluded?(tag)
      classes << "globally_excluded"
    elsif current_user.subscribed?(tag)
      classes << "subscribed"
    end
    classes.join(" ")
  end

  def feed_classes(feed)
    if current_user.globally_excluded?(feed)
      "globally_excluded"
    end
  end

  def tag_state(tag)
    if current_user.globally_excluded?(tag)
      t("winnow.tags.general.globally_excluded")
    elsif current_user.subscribed?(tag)
      t("winnow.tags.general.subscribed")
    end
  end

  def rounded_button_function(name, function, html_options = {}, &block)
    (html_options[:class] ||= "") << " button"
    if icon = html_options.delete(:icon)
      link_to_function(content_tag(:span, name, :class => "icon #{icon}"), function, html_options, &block)
    else
      link_to_function(name, function, html_options, &block)
    end
  end

  def rounded_button_link(name, options = {}, html_options = {})
    (html_options[:class] ||= "") << " button"
    if icon = html_options.delete(:icon)
      link_to(content_tag(:span, name, :class => "icon #{icon}"), options, html_options)
    else
      link_to(name, options, html_options)
    end
  end
end
