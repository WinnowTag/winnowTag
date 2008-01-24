# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
module ApplicationHelper  
  include DateHelper
  
  # Permit methods in the ApplicationController to be called from views.
  def method_missing(method, *args, &block)
    if ApplicationController.instance_methods.include? method.to_s
      controller.send(method, *args, &block)
    else
      super
    end
  end
  
  def tab_selected(controller, action = nil)
    "selected" if params[:controller] == controller and (action.nil? or params[:action] == action)
  end
      
  def show_flash
    [:notice, :warning, :error].map do |name|
      close = link_to_function(image_tag('cross.png'), "$('#{name}').hide()", :class => 'close', :title => 'Close Message')
      content_tag :div, " #{close} #{flash[name]}", :id => name, :class => "clearfix", :style => flash[name].blank? ? "display: none" : nil
    end.join
  end
  
  def property_row(obj, property, title = property.to_s.humanize, *args)
    if args.any?
      data = obj.send(property, *args)
    else
      data = obj.send(property)
    end
    
    css_class = case data
                when Numeric
                  "number"
                when Time
                  data = format_date(data)
                  "date"
                end

    
    content_tag('tr',
      content_tag('th', title) +
      content_tag('td', data, :class => css_class)
    )
  end
  
  def appendable_url_for(options = {})
    url = url_for(options)
    
    if url =~ /.*\?.*/
      url += '&'
    else
      url += '?'
    end
  end
  
  # flattens nested params - only handles one level of nesting
  def flatten_params(options = {})
    skip = Array(options[:skip])
    params.inject({}) do |hash, (key, value)|
      if value.is_a? Hash and not(skip.include?(key))
        value.inject(hash) do |hash, subentry|
          subkey, subvalue = subentry
          hash["#{key}[#{subkey}]"] = subvalue
          hash
        end
      elsif not(skip.include?(key))
        hash[key] = value
      end
      
      hash
    end
  end
  
  def pagination_links(paginator, options = {}, html_options = {})
    options = options.merge :link_to_current_page => true
    options[:params] ||= {}
    
    pagination_links_each(paginator, options) do |page|
      if page == paginator.current_page.number
        content_tag('span', page, :class => 'current_page')
      else
        content_tag('span', link_to(page, options[:params].merge(:page => page), html_options))
      end
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
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['paramName'] = %('#{options[:param_name]}') if options[:param_name]
    js_options['method'] = %('#{options[:method]}') if options[:method]
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
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +
        tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :size => 30, :results => 5, :placeholder => "Search...", :autosave => name) +      
        content_tag(:span, nil, :class => "sbox_r srch_clear", :onclick => options[:clear][:onclick]), 
      :class => "applesearch"
  end

  def globally_exclude_check_box(tag_or_feed)
    url = if tag_or_feed.is_a?(Tag)
      globally_exclude_tag_path(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      globally_exclude_feed_path(tag_or_feed)
    end
    
    check_box_tag dom_id(tag_or_feed, "globally_exclude"), "1",current_user.globally_excluded?(tag_or_feed), 
      :onclick => remote_function(:url => url, :with => "{globally_exclude: this.checked}")
  end
  
  def tag_name_with_tooltip(tag, options = {})
    content_tag :span, h(tag.name), options.merge(:title => tag.user_id == current_user.id ? nil :  "from #{tag.user.display_name}")
  end
  
  def feed_filter_controls(feeds, options = {})
    content_tag :ul, feeds.map { |feed| feed_filter_control(feed, options) }.join, options.delete(:ul_options) || {}
  end
  
  def feed_filter_control(feed, options = {})
    unread_item_count = current_user.unread_items.for(feed).size
    if true or unread_item_count.zero?
      html = ""
    else
      html = content_tag(:span, "(#{unread_item_count})", :class => "unread_count", :title => "#{unread_item_count} unread items in this feed")
    end
    url  =  case options[:remove]
      when :subscription then subscribe_feed_path(feed, :subscribe => false)
      when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(feed))
    end
    html << link_to_function(image_tag("cross.png"), "this.up('li').remove(); #{remote_function(:url => url, :method => :put)}", :class => "remove") << " "
    html << link_to_function(feed.title, "itemBrowser.toggleSetFilters({feed_ids: '#{feed.id}'})", :class => "name", :title => "#{feed.feed_items.size} items in this feed")
    
    html =  content_tag(:div, html, :class => "show_feed_control")
    html << content_tag(:span, highlight(feed.title, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "feed_name") if options[:auto_complete]

    class_names = ["feed"]
    class_names << "draggable" if options[:draggable]
    html =  content_tag(:li, html, :id => dom_id(feed), :class => class_names.join(" "), :subscribe_url => subscribe_feed_path(feed, :subscribe => true))
    html << draggable_element(dom_id(feed), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }", :constraint => "'vertical'") if options[:draggable]
    html
  end
  
  def tag_filter_controls(tags, options = {})
    content_tag :ul, tags.map { |tag| tag_filter_control(tag, options) }.join, options.delete(:ul_options) || {}
  end
  
  def tag_filter_control(tag, options = {})
    unread_item_count = current_user.unread_items.for(tag).size
    if true or unread_item_count.zero?
      html = ""
    else
      html = content_tag(:span, "(#{unread_item_count})", :class => "unread_count", :title => "#{unread_item_count} unread items with this tag")
    end
    if options[:remove] == :subscription && current_user == tag.user
      options = options.except(:remove)
      options[:remove] = :sidebar
    end
    url  =  case options[:remove]
      when :subscription then subscribe_tag_path(tag, :subscribe => false)
      when :sidebar      then sidebar_tag_path(tag, :sidebar => false)
      when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(tag))
    end
    html << link_to_function(image_tag("cross.png"), "this.up('li').remove(); #{remote_function(:url => url, :method => :put)}", :class => "remove") << " " if options[:remove]
    html << link_to_remote(image_tag("pencil.png"), :url => tag_path(tag), :method => :put, :with => "{'tag[name]': name}", :condition => %W|name = prompt("Name:", "#{tag.name}")|, :html => { :class => "edit" }) if current_user == tag.user
    html << link_to_function(tag_name_with_tooltip(tag), "itemBrowser.toggleSetFilters({tag_ids: '#{tag.id}'})", :class => "name")
    
    html =  content_tag(:div, html, :class => "show_tag_control")
    html << content_tag(:span, highlight(tag.name, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "tag_name") if options[:auto_complete]
    
    class_names = ["tag"]
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
end
