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
  
  def tab_selected(controller, action = nil)
    "selected" if params[:controller] == controller and (action.nil? or params[:action] == action)
  end
  
  def navigation_bar
    tabs = ''
    tabs << link_to('Feeds', feeds_path(:view_id => @view), :class => tab_selected('feeds')) 
  	tabs << link_to('Feed Items', feed_items_path(:view_id => @view), :class => tab_selected('feed_items')) 
  	tabs << link_to('Tags', tags_path(:view_id => @view), :class => tab_selected('tags'))
  	       
  	if current_user and is_admin?
  	  tabs << link_to('Admin', admin_path(:view_id => @view), :class => tab_selected('admin'))
		end 
  		
  	tabs << link_to("About", about_path(:view_id => @view), :class => tab_selected('about'))
  	
  	tabs
  end
  
  def show_flash
    [:notice, :warning, :message, :error].map do |name|
      if flash[name]
        content_tag 'div', 
            image_tag("#{name}.png", :class => 'flash_icon', :size => '16x16', :alt => '') +
            flash[name].to_s + 
            link_to_function(
                    image_tag('cross.png',
                              :size => '11x11',
                              :alt => 'X',
                              :class => 'flash_icon'), 
                    "$('#{name}').hide();", 
                    :id => 'close_flash',
                    :title => 'Close message') , 
          :id => name.to_s
      end
    end.compact.join
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
    if options[:requires].nil? or options[:requires] == true or (options[:requires].is_a?(String) and permit?(options.delete(:requires)))
      if options.delete(:remote)
        css_class = 'control'
        
        if options.delete(:disabled)
          css_class += ' disabled'
        end
        
        options[:url] = url
        options[:condition] = '!this.hasClassName("disabled")'
        html_options = (options.delete(:html) or Hash.new)
        link_to_remote(content, options, html_options.merge(:class => css_class))
      else
        link_to_unless(options.delete(:disabled), content, url, options.merge(:class => 'control')) do |name|
          link_to(name, '#', :class => 'disabled control')
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
end
