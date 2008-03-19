# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
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
    button_to_function 'Auto-tag', :id => 'classification_button' do |page|
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
    tags = feed_item.taggings_by_user(current_user, :tags => tags_to_display)

    html = tags.map do |tag, taggings|
      tag_control_for(feed_item, tag, classes_for_taggings(taggings))
    end.join(" ")
    
    current_user.subscribed_tags.group_by(&:user).each do |user, subscribed_tags|
      more_tags = feed_item.taggings_by_user(user, :tags => tags_to_display)
      
      html += more_tags.map do |tag, taggings|
        if tagging = Array(taggings).first
          tag_span = tag_name_with_tooltip(tag)
          content_tag(:li, tag_span, :class => classes_for_taggings(tagging, [:public, :name]).join(" "))
        end
      end.compact.join(" ")
    end
    
    content_tag "ul", html, :class => "tag_list clearfix stop", :id => dom_id(feed_item, "tag_controls")
  end
  
  def tags_to_display
    if show_manual_taggings? && params[:tag_ids]
      params[:tag_ids].split(",").map(&:to_i)
    else
      (current_user.sidebar_tags + current_user.subscribed_tags - current_user.excluded_tags).map(&:id) + params[:tag_ids].to_s.split(",").map(&:to_i)
    end
  end
  
  def tag_control_for(feed_item, tag, classes)
    controls  = content_tag(:span, nil, :class => "add", :onclick => "add_tag('#{dom_id(feed_item)}', #{tag.name.to_json}, true);", 
                                        :onmouseover => "show_control_tooltip(this, $(this).up('li'), #{tag.name.to_json});")
    controls << content_tag(:span, nil, :class => "remove", :onclick => "remove_tag('#{dom_id(feed_item)}', #{tag.name.to_json});", 
                                        :onmouseover => "show_control_tooltip(this, $(this).up('li'), #{tag.name.to_json});")

    content   = content_tag(:span, h(tag.name), :class => "name")
    content  << content_tag(:span, controls, :class => "controls", :style => "display:none")

    content_tag(:li, content, 
        :id => dom_id(feed_item, "tag_control_for_#{tag.name}_on"), :class => classes.join(" "), 
        :onmouseover => "show_tag_tooltip(this, #{tag.name.to_json}); show_tag_controls(this);")
  end
  
	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
    
    if tagging = taggings.first
      if tagging.classifier_tagging?
        classes << "classifier"
      elsif tagging.positive?
        classes << "positive"
      elsif tagging.negative?
        classes << "negative"
      end
    end
    
    if taggings.size > 1 && taggings.last(taggings.size - 1).detect(&:classifier_tagging?)
      classes << "classifier"
    end
    
    classes.uniq
  end
end
