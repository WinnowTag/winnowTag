# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedItemsHelper
  include BiasSliderHelper
  STRIPPED_ELEMENTS = %w(script style link meta) unless const_defined?(:STRIPPED_ELEMENTS)
  
  def clean_html(html)
    unless html.blank? 
      doc = Hpricot(html)
      doc.search(STRIPPED_ELEMENTS.join(',')).each {|e| e.parent.children.delete(e) }
      doc.to_s
    end
  end
  
  def link_to_feed(feed, options = {})
    if feed.alternate 
      link_to(feed.title, feed.alternate, :target => "_blank") 
    else
      feed.title
    end
  end
  
  def link_to_feed_item(feed_item)
    if feed_item.link 
      link_to(feed_item.title, feed_item.link, :target => "_blank") 
    else
      feed_item.title
    end
  end
  
  def toggle_read_unread_button
    link_to_function "", "itemBrowser.toggleReadUnreadItem(this.up('.item'))", 
          :onmouseover => "this.title = 'Click to mark as ' + ($(this).up('.item').match('.read') ? 'unread' : 'read');"
  end
    
  # Creates the classification button.
  #
  # When pressed, the classification button creates a Classification
  # Javascript object that handles the interaction with the server.
  # See Classification and Classification.createItemBrowserClassification
  # in itembrowser.js.
  #
  # The way the routes are setup for the classifier controller means
  # that we can always identify a single classifier to use by either
  # a prefix path, as in the case of a tag publications classifier 
  # or using '/classifier' which is the classifier belonging
  # to the current user.
  #
  def classification_button
    button_to_function 'Start', :id => 'classification_button' do |page|
      page << <<-END_JS
         classification = Classification.createItemBrowserClassification(#{classifier_path.to_json});
         classification.start();
      END_JS
    end
  end
  
  def cancel_classification_button
    button_to_function("Stop", 'cancelClassification();', :style => "display: none", :id => 'cancel_classification_button')
  end
  
  def classifier_progress_title
    "Classify changed tags"
  end
  
  def show_manual_taggings?
    params[:manual_taggings] =~ /true/i ? true : false 
  end
 
  def tag_controls(feed_item)
    if show_manual_taggings?
      tags = feed_item.taggings_by_user(current_user, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : nil)
    else
      tags = feed_item.taggings_by_user(current_user)
    end

    html = ""    
    tags.each do |tag, taggings|
      content = content_tag("span", h(tag.name), :class => "name")
      controls = ""
      controls << content_tag("span", nil, :class => "add", :onclick => "add_tag('#{dom_id(feed_item)}', #{tag.name.to_json}, true);", :onmouseover => "show_control_tooltip(this, $(this).up('li'), #{tag.name.to_json});")
      controls << content_tag("span", nil, :class => "remove", :onclick => "remove_tag('#{dom_id(feed_item)}', #{tag.name.to_json});", :onmouseover => "show_control_tooltip(this, $(this).up('li'), #{tag.name.to_json});")
      content << content_tag("span", controls, :class => "controls", :style => "display:none")
      classes = classes_for_taggings(taggings).join(' ')
      unless classes.blank?
        html << content_tag('li', content, 
          :id => dom_id(feed_item, "tag_control_for_#{tag.name}_on"), :class => classes, 
          :onmouseover => "show_tag_tooltip(this, #{tag.name.to_json}); show_tag_controls(this);") + " "
      end
    end
    
    current_user.subscribed_tags.group_by(&:user).each do |user, subscribed_tags|
      if show_manual_taggings?
        more_tags = feed_item.taggings_by_user(user, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : subscribed_tags)
      else
        more_tags = feed_item.taggings_by_user(user, :tags => subscribed_tags)
      end
      more_tags.collect do |tag, taggings|
        if tagging = Array(taggings).first
          tag_span = tag_name_with_tooltip(tag)
          html << content_tag(:li, tag_span, :class => classes_for_taggings(tagging, [:public, :name]).join(" ")) << " "
        end
      end
    end
    
    content_tag "ul", html, :class => "tag_list clearfix", :id => dom_id(feed_item, "tag_controls")
  end
  
  def unused_tag_controls(feed_item) 
    unused_tags = current_user.tags - feed_item.tags 
     
    html = unused_tags.map do |tag| 
      content_tag('li', content_tag("span", h(tag.name), :class => "name"), 
        :id => dom_id(feed_item, "unused_tag_control_for_#{tag.name}_on"), :class => "cursor",  
        :onclick => "add_tag('#{dom_id(feed_item)}', '#{escape_javascript(tag.name)}');",  
        :onmouseover => "show_tag_tooltip(this, '#{escape_javascript(tag.name)}');") 
    end.join(" ") 
    content_tag "ul", html, :class => "tag_list unused clearfix", :id => dom_id(feed_item, "unused_tag_controls") 
  end   

	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
    
    if taggings.size == 1 and tagging = taggings.first
      if tagging.classifier_tagging?
        classes << "classifier"
      elsif tagging.positive?
        classes << "positive"
      elsif tagging.negative?
        classes << "negative"
      end
    elsif taggings.size > 1
      classes += classes_for_taggings(taggings.first)
      taggings.last(taggings.size - 1).each do |tagging|
        if tagging.classifier_tagging?
          classes << "classifier"
        end
      end
    end
    
    classes.uniq
  end
end
