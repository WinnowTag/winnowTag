# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module ApplicationHelper  
  include DateHelper
  
  def tab_selected(controller, action = nil)
    "selected" if controller_name == controller and (action.nil? or action_name == action)
  end
  
  def show_flash
    [:notice, :warning, :error, :confirm].map do |name|
      close = link_to_function(image_tag('cross.png'), "$('#{name}').hide()", :class => 'close', :title => _(:close_flash_tooltip))
      content_tag :div, " #{close} #{flash[name]}", :id => name, :class => "clearfix", :style => flash[name].blank? ? "display:none" : nil
    end.join
  end
  
  def show_unread_messages
    unread_messages = Message.find_unread_for_user_and_global(current_user)
    if unread_messages.empty?
      content_tag :div, "", :id => "message", :class => "clearfix", :style => "display:none"
    elsif unread_messages.size == 1
      message = unread_messages.first
      close = link_to_remote(image_tag('cross.png'), :url => mark_read_message_path(message), :method => :put, :html => { :class => 'close' })
      content_tag :div, "#{close} #{message.body}", :id => "message", :class => "clearfix"
    else
      close = link_to_remote(image_tag('cross.png'), :url => mark_read_messages_path, :method => :put, :html => { :class => 'close' })
      content_tag :div, "#{close} #{_(:multiple_unread_messages, info_path)}", :id => "message", :class => "clearfix"
    end
  end
  
  # Provides some assistance over link_to for special control links
  #
  # == New Parameters
  #   * disabled - if true the link will be disabled
  #   * requires - a permission expression that if permits?(options[:requires]) evaluates to true
  #                the link will be rendered, otherwise it wont
  def control_link(content, url, options = {})
    html_options = options.delete(:html) || {}
    css_classes = ["control"]
    css_classes << html_options[:class] unless html_options[:class].blank?
    
    if options[:requires].nil? or options[:requires] == true or (options[:requires].is_a?(String) and permit?(options.delete(:requires)))
      if options.delete(:remote)
        
        if options.delete(:disabled)
          css_classes << 'disabled'
        end
        
        options[:url] = url
        options[:condition] = '!this.hasClassName("disabled")'
        link_to_remote(content, options, html_options.merge(:class => css_classes.join(" ")))
      else
        link_to_unless(options.delete(:disabled), content, url, options.merge(:class => css_classes.join(" "))) do |name|
          css_classes << "disabled"
          link_to(name, '#', html_options.merge(:class => css_classes.join(" ")))
        end
      end
    elsif options[:alternate]
      options[:alternate]
    end
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
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['paramName'] = %('#{options[:param_name]}') if options[:param_name]
    js_options['method'] = %('#{options[:method]}') if options[:method]
    js_options['onEnterHover'] = %('#{options[:on_enter_hover]}') if options[:on_enter_hover]
    js_options['onLeaveHover'] = %('#{options[:on_leave_hover]}') if options[:on_leave_hover]
    js_options['onComplete'] = %('#{options[:on_complete]}') if options[:on_complete]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
    
    function << ')'

    javascript_tag(function)
  end
  
  def show_sidebar?
    cookies[:show_sidebar] !~ /false/i
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
  
  def search_field_tag(name, value = nil, options = {})
    options[:clear] ||= {}
    options[:placeholder] ||= _(:default_search_placeholder)
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +      
      content_tag(:span, nil, :class => "sbox_r srch_clear", :onclick => options[:clear][:onclick]) +
      tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :results => 5, :placeholder => options[:placeholder], :autosave => name), 
      :class => "applesearch"
  end

  def globally_exclude_check_box(tag_or_feed)
    url = if tag_or_feed.is_a?(Tag)
      globally_exclude_tag_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      globally_exclude_feed_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Remote::Feed)
      globally_exclude_feed_path(:id => tag_or_feed.id)
    end
    
    check_box_tag dom_id(tag_or_feed, "globally_exclude"), "1",current_user.globally_excluded?(tag_or_feed), 
      :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}")
  end
  
  def tag_name_with_tooltip(tag, options = {})
    content_tag :span, h(tag.name), options.merge(:title => tag.user_id == current_user.id ? nil : _(:public_tag_tooltip, tag.user.display_name))
  end
  
  def feed_filter_controls(feeds, options = {})
    content =  feeds.map { |feed| feed_filter_control(feed, options) }.join
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
    html = link_to_function(image_tag("cross.png"), "#{function}this.up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => url, :method => :put)}", :class => "remove") << " "
    html << link_to_function(feed.title, "itemBrowser.toggleSetFilters({feed_ids: '#{feed.id}'}, event)", :class => "name", :title => _(:feed_items_count_tooltip, feed.feed_items.size))
    
    html =  content_tag(:div, html, :class => "show_feed_control")
    html << content_tag(:span, highlight(feed.title, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "feed_name") if options[:auto_complete]

    class_names = [dom_id(feed)]
    class_names << "draggable" if options[:draggable]
    html =  content_tag(:li, html, :id => dom_id(feed), :class => class_names.join(" "), :subscribe_url => subscribe_feed_path(feed, :subscribe => true))
    html << draggable_element(dom_id(feed), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }", :constraint => "'vertical'") if options[:draggable]
    html
  end
  
  def tag_filter_controls(tags, options = {})
    content =  tags.map { |tag| tag_filter_control(tag, options) }.join
    content << content_tag(:li, _(:create_tag, options[:auto_complete]), :id => "add_new_tag", :name => options[:auto_complete]) if options[:add]
    content_tag :ul, content, options.delete(:ul_options) || {}
  end
  
  def tag_filter_control(tag, options = {})
    if options[:remove] == :subscription && current_user == tag.user
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
    html =  link_to_function(image_tag("cross.png"), "#{function}this.up('li').remove();itemBrowser.styleFilters();#{remote_function(:url => url, :method => :put)};", :class => "remove") << " "
    html << image_tag("pencil.png", :id => dom_id(tag, "edit"), :class => "edit") if current_user == tag.user
    html << link_to_function(tag.name, "itemBrowser.toggleSetFilters({tag_ids: '#{tag.id}'}, event)", :class => "name", :id => dom_id(tag, "name"), :title => tag.user_id == current_user.id ? nil :  _(:public_tag_tooltip, tag.user.display_name))
    html << in_place_editor(dom_id(tag, "name"), :url => tag_path(tag), :options => "{method: 'put'}", :param_name => "tag[name]",
              :external_control => dom_id(tag, "edit"), :external_control_only => true, :click_to_edit_text => "", 
              :on_enter_hover => "", :on_leave_hover => "", :on_complete => "",
              :save_control => false, :cancel_control => false) if tag.user_id == current_user.id
    
    html =  content_tag(:div, html, :class => "show_tag_control")
    html << content_tag(:span, highlight(tag.name, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "tag_name") if options[:auto_complete]
    
    class_names = [dom_id(tag)]
    class_names << "public" if tag.user_id != current_user.id
    class_names << "draggable" if options[:draggable]
    url  =  case options[:remove]
      when :subscription then subscribe_tag_path(tag, :subscribe => true)
      when :sidebar      then sidebar_tag_path(tag, :sidebar => true)
    end
    html =  content_tag(:li, html, :id => dom_id(tag), :class => class_names.join(" "), :subscribe_url => url)
    html << draggable_element(dom_id(tag), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }", :constraint => "'vertical'") if options[:draggable]
    html
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
end
