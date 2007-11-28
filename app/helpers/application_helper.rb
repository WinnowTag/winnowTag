# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# application_helper.rb

# Methods added to this helper will be available to all templates in the application.

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
  
  def referrer_with_new_view(view)
    view_id = view.is_a?(View) ? view.id : view
    request.env['HTTP_REFERER'].gsub(/view_id=\d+/, "view_id=#{view_id}")
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
  
  def options_for_view_select
    views = current_user.views.saved.map { |v| [v.name, v.id] }
    views.unshift(["Unsaved View", @view.id]) if @view.unsaved?
    options_for_select(views, @view.id)
  end
  
  def filter_control tooltip, clazz, selected, options = {}
    classes = ["filter_control", clazz]
    classes << "selected" if selected
    classes << "disabled" if options[:disabled]
    
    if options[:onclick]
      onclick = "updateFilterControl(this); #{options[:onclick]}"
    else
      onclick = "updateFilterControl(this, '#{options[:add_url]}', '#{options[:remove_url]}');"
    end
    
    content_tag :span, nil, :title => tooltip, :class => classes.join(" "), :onclick => onclick, :id => options[:id]
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
    if cookies["show_sidebar"]
      cookies["show_sidebar"].first =~ /true/i
    end
  end
  
  def search_field_tag(name, value = nil, options = {})
    options[:clear] ||= {}
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +
        tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :size => 30, :results => 5, :placeholder => "Search...", :autosave => name) +      
        content_tag(:span, nil, :class => "sbox_r srch_clear", :onclick => options[:clear][:onclick]), 
      :class => "applesearch"
  end
end
