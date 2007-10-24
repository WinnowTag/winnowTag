# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class View < ActiveRecord::Base
  acts_as_state_machine :initial => :unsaved
  
  state :unsaved
  state :saved
    
  belongs_to :user
  
  serialize :tag_filter
  serialize :feed_filter
  
  def initialize(*args, &block)
    super(*args, &block)
    
    self.feed_filter ||= { :always_include => [], :include => [], :exclude => [] }
    self.tag_filter ||= { :include => [], :exclude => [] }
  end
  
  def add_feed(feed_state, feed_id)
    feed_state, feed_id = feed_state.to_sym, feed_id.to_i

    other_feed_states(feed_state).each { |other_feed_state| feed_filter[other_feed_state].delete(feed_id) }
    feed_filter[feed_state] << feed_id unless feed_filter[feed_state].include?(feed_id)
  end
  
  def remove_feed(feed_id)
    feed_filter[:always_include].delete(feed_id.to_i)
    feed_filter[:include].delete(feed_id.to_i)
    feed_filter[:exclude].delete(feed_id.to_i)
  end
  
  def add_tag(tag_state, tag)
    tag_state, tag = tag_state.to_sym, arg_to_tag(tag)
    
    if tag and !tag_filter[tag_state].include?(tag)
      tag_filter[other_tag_state(tag_state)].delete(tag)
      tag_filter[tag_state] << tag
    end
  end
  
  def remove_tag(tag)
    tag = arg_to_tag(tag)
    
    tag_filter[:include].delete(tag)
    tag_filter[:exclude].delete(tag)
  end
    
  def update_filters(params = {})
    if params[:mode] == 'tag_inspect'
      self.tag_inspect_mode = true
     elsif params[:mode] == 'normal'
      self.tag_inspect_mode = false
    end

    new_feed_filter = params[:feed_filter]
    if new_feed_filter =~ /all/i
      self.feed_filter[:always_include].clear
      self.feed_filter[:include].clear
      self.feed_filter[:exclude].clear
    elsif new_feed_filter
      new_feed_filter_action = params[:feed_filter_action] || 'add'

      if new_feed_filter_action =~ /add/i
        new_feed_filter_state = params[:feed_filter_state] || 'include'
        add_feed new_feed_filter_state, new_feed_filter
      elsif new_feed_filter_action =~ /remove/i
        remove_feed new_feed_filter
      end
    end
    
    new_tag_filter = params[:tag_filter]
    if new_tag_filter =~ /all/i
      self.tag_filter[:include].clear
      self.tag_filter[:exclude].clear
    elsif new_tag_filter
      new_tag_filter_action = params[:tag_filter_action] || 'add'

      if new_tag_filter_action =~ /add/i
        new_tag_filter_state = params[:tag_filter_state] || 'include'
        add_tag new_tag_filter_state, new_tag_filter
      elsif new_tag_filter_action =~ /remove/i
        remove_tag new_tag_filter
      end
    end
  
    new_text_filter = params[:text_filter]
    if params.has_key?(:text_filter) and new_text_filter.blank?
      self.text_filter = nil
    elsif new_text_filter
      self.text_filter = new_text_filter
    end
    
    if params[:show_untagged]
      self.show_untagged = params[:show_untagged]
    end
  end
  
  def dup
    View.new :user => user, :tag_filter => tag_filter.dup, :feed_filter => feed_filter.dup, 
             :text_filter => text_filter, :tag_inspect_mode => tag_inspect_mode, :show_untagged => show_untagged
  end
  
  def dup!
    view = dup
    view.save!
    view
  end
  
  def set_as_default!
    user.views.update_all(["`default` = ?", false])
    update_attribute :default, true
  end
  
  class << self
    def saved
      find_in_state(:all, :saved)
    end
  end
  
private
  def arg_to_tag(arg)
    if arg.is_a?(Tag)
      arg.id
    elsif arg.to_s =~ /^\d+$/
      arg.to_i
    else
      raise ArgumentError.new("Argument must be a tag or tag id but was #{arg.inspect}")
    end
  end

  def other_tag_state(state)
    state.to_sym == :include ? :exclude : :include
  end
  
  def other_feed_states(state)
    feed_states = [:always_include, :include, :exclude]
    feed_states.delete(state)
    feed_states
  end
end
