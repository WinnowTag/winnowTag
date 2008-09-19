# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper  
  include DateHelper

  STRIPPED_ELEMENTS = %w(script style link meta) unless const_defined?(:STRIPPED_ELEMENTS)
  
  # TODO: Replace usages with sanitize
  def clean_html(html)
    unless html.blank? 
      doc = Hpricot(html)
      doc.search(STRIPPED_ELEMENTS.join(',')).each {|e| e.parent.children.delete(e) }
      doc.to_s
    end
  end
  
  def tab_selected(controller, action = nil)
    "selected" if controller_name == controller and (action.nil? or action_name == action)
  end
  
  def show_flash_messages
    javascript = [:notice, :warning, :error].map do |name|
      "Message.add('#{name}', #{flash[name].to_json});" unless flash[name].blank?
    end.join
    
    javascript << Message.find_unread_for_user_and_global(current_user).map do |message|
      Message.mark_read_for(current_user.id, message.id)
      
      if message.user
        "Message.add('error', #{message.body.to_json});"
      else
        "Message.add('warning', #{message.body.to_json});"
      end
    end.join if current_user
    
    javascript_tag(javascript) unless javascript.blank?
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
  
  def open_tags?
    cookies[:tags] =~ /true/i
  end
  
  def open_feeds?
    cookies[:feeds] =~ /true/i
  end
  
  def open_folders?
    cookies[:folders] =~ /true/i
  end
  
  def search_field_tag(name, value = nil, options = {})
    options[:clear] ||= {}
    options[:placeholder] ||= _(:default_search_placeholder)
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +      
      tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :results => 5, :placeholder => options[:placeholder], :autosave => name) +
      content_tag(:span, nil, :class => "sbox_r srch_clear"),
      :class => "applesearch clearfix"
  end

  def globally_exclude_check_box(tag_or_feed)
    url = if tag_or_feed.is_a?(Tag)
      globally_exclude_tag_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      globally_exclude_feed_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Remote::Feed)
      globally_exclude_feed_path(:id => tag_or_feed.id)
    end
    
    check_box_tag dom_id(tag_or_feed, "globally_exclude"), "1", 
      tag_or_feed.respond_to?(:state) ? tag_or_feed.globally_excluded_by_current_user? : current_user.globally_excluded?(tag_or_feed),
      :id => "#{dom_id(tag_or_feed, 'globally_exclude')}", :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}")
  end
  
  def feed_filter_controls(feeds, options = {})
    content =  feeds.map { |feed| feed_filter_control(feed, options) }.join
    # TODO: sanitize
    content << content_tag(:li, _(:create_feed, options[:auto_complete]), :id => "add_new_feed", :url => options[:auto_complete]) if options[:add]
    content_tag :ul, content, options.delete(:ul_options) || {}
  end
  
  def feed_filter_control(feed, options = {})   
    url      = case options[:remove]
      when :subscription then subscribe_feed_path(feed, :subscribe => false)
      when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(feed))
    end
    function = case options[:remove]
      when :subscription then "itemBrowser.removeFilters({feed_ids: '#{feed.id}'});"
    end

    html = link_to_function("Remove", "#{function}this.up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => url, :method => :put)}", :class => "remove")
    html = content_tag(:div, html, :class => "actions")

    # TODO: sanitize
    html << link_to_function(feed.title, "itemBrowser.toggleSetFilters({feed_ids: '#{feed.id}'}, event)", :class => "name")
    
    html =  content_tag(:div, html, :class => "filter")
    # TODO: sanitize
    html << content_tag(:span, highlight(feed.title, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "auto_complete_name") if options[:auto_complete]

    class_names = [dom_id(feed), "clearfix", "feed"]
    class_names << "draggable" if options[:draggable]
    html =  content_tag(:li, html, :id => dom_id(feed), :class => class_names.join(" "), :subscribe_url => subscribe_feed_path(feed, :subscribe => true))
    html << draggable_element(dom_id(feed), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }") if options[:draggable]
    html
  end
  
  def tag_filter_controls(tags, options = {})
    content =  tags.map { |tag| tag_filter_control(tag, options) }.join
    # TODO: sanitize
    content << content_tag(:li, _(:create_tag, options[:auto_complete]), :id => "add_new_tag", :name => options[:auto_complete]) if options[:add]
    content_tag :ul, content, options.delete(:ul_options) || {}
  end
  
  def tag_filter_control(tag, options = {})
    if options[:remove] == :subscription && current_user.id == tag.user_id
      options = options.except(:remove)
      options[:remove] = :sidebar
    end
    url      = case options[:remove]
      when :subscription           then unsubscribe_tag_path(tag)
      when :sidebar                then sidebar_tag_path(tag, :sidebar => false)
      when Folder                  then remove_item_folder_path(options[:remove], :item_id => dom_id(tag))
    end
    function = case options[:remove]
      when :subscription, :sidebar then "itemBrowser.removeFilters({tag_ids: '#{tag.id}'});"
    end

    html  = ""
    html << link_to_function("Rename", "var new_tag_name = prompt('Tag Name:', this.up('.tag').down('.name').innerHTML.unescapeHTML()); if(new_tag_name) { #{remote_function(:url => tag_path(tag), :method => :put, :with => "'tag[name]=' + new_tag_name")} }", :class => "edit") if options[:editable] && current_user.id == tag.user_id
    html << link_to_function("Remove", "#{function}this.up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => url, :method => :put)}", :class => "remove")
    html  = content_tag(:div, html, :class => "actions")

    # TODO: sanitize
    html << link_to_function(tag.name, "itemBrowser.toggleSetFilters({tag_ids: '#{tag.id}'}, event)", :class => "name", :id => dom_id(tag, "name"))
    
    html =  content_tag(:div, html, :class => "filter clearfix")
    # TODO: sanitize
    html << content_tag(:span, highlight(tag.name, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "auto_complete_name") if options[:auto_complete]
    
    class_names = [dom_id(tag), "clearfix", "tag"]
    class_names << "public" if tag.user_id != current_user.id
    class_names << "draggable" if options[:draggable]
    url  =  case options[:remove]
      when :subscription then subscribe_tag_path(tag, :subscribe => true)
      when :sidebar      then sidebar_tag_path(tag, :sidebar => true)
    end
    html =  content_tag(:li, html, :id => dom_id(tag), :class => class_names.join(" "), :subscribe_url => url, :title => tag_tooltip(tag))
    html << draggable_element(dom_id(tag), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }") if options[:draggable]
    html
  end
  
  def tag_tooltip(tag)
    if tag.user_id == current_user.id 
      _(:tag_tooltip, tag.positive_count, tag.negative_count, tag.classifier_count)
    else
      _(:public_tag_tooltip, tag.user.display_name, tag.positive_count, tag.negative_count, tag.classifier_count)
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
    if tag.respond_to?(:state) ? tag.globally_excluded_by_current_user? : current_user.globally_excluded?(tag)
      "globally_excluded"
    elsif tag.respond_to?(:state) ? tag.subscribed_by_current_user? : current_user.subscribed?(tag)
      "subscribed"
    end.to_s + " " + dom_id(tag)
  end

  def feed_classes(feed)
    if current_user.globally_excluded?(feed)
      "globally_excluded"
    end
  end

  def tag_state(tag)
    if tag.respond_to?(:state) ? tag.globally_excluded_by_current_user? : current_user.globally_excluded?(tag)
      "Excluded"
    elsif tag.respond_to?(:state) ? tag.subscribed_by_current_user? : current_user.subscribed?(tag)
      "Subscribed"
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
