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
  has_many :tag_filters, :class_name => "ViewTagState", :dependent => :delete_all do
    def include
      self.select { |tag_filter| tag_filter.state == "include" }
    end
    
    def exclude
      self.select { |tag_filter| tag_filter.state == "exclude" }
    end
    
    def includes?(state, tag)
      tag_id = View.arg_to_tag(tag)
      self.detect { |tag_filter| tag_filter.state == state.to_s && tag_filter.tag_id == tag_id }
    end
  end

  has_many :feed_filters, :class_name => "ViewFeedState", :dependent => :delete_all do
    def always_include
      self.select { |feed_filter| feed_filter.state == "always_include" }
    end
    
    def include
      self.select { |feed_filter| feed_filter.state == "include" }
    end

    def includes?(state, feed)
      feed_id = View.arg_to_feed(feed)
      self.detect { |feed_filter| feed_filter.state == state.to_s && feed_filter.feed_id == feed_id }
    end
  end
    
  def add_feed(feed_state, feed)
    feed_state, feed_id = feed_state.to_sym, arg_to_feed(feed)
    
    remove_feed(feed_id)
    feed_filters.create :feed_id => feed_id, :state => feed_state.to_s
  end
  
  def remove_feed(feed)
    feed_id = arg_to_feed(feed)
    if feed_filter = (feed_filters.includes?(:always_include, feed_id) || feed_filters.includes?(:include, feed_id))
      feed_filters.delete(feed_filter)
    end
  end
  
  def add_tag(tag_state, tag)
    tag_state, tag_id = tag_state.to_sym, arg_to_tag(tag)
    
    if tag_id
      remove_tag(tag_id)
      tag_filters.create :tag_id => tag_id, :state => tag_state.to_s
    end    
  end
  
  def remove_tag(tag)
    tag_id = arg_to_tag(tag)
    if tag_filter = (tag_filters.includes?(:include, tag_id) || tag_filters.includes?(:exclude, tag_id))
      tag_filters.delete(tag_filter)
    end
  end
    
  def update_filters(params = {})
    if params[:mode] == 'tag_inspect'
      self.tag_inspect_mode = true
     elsif params[:mode] == 'normal'
      self.tag_inspect_mode = false
    end

    new_feed_filter = params[:feed_filter]
    if new_feed_filter =~ /all/i
      feed_filters.clear
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
      tag_filters.clear
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
  end
  
  def dup!
    view = View.create! :user => user, :text_filter => text_filter, :tag_inspect_mode => tag_inspect_mode, :show_untagged => show_untagged
    tag_filters.each do |tag_filter|
      view.tag_filters.create :tag_id => tag_filter.tag_id, :state => tag_filter.state
    end
    feed_filters.each do |feed_filter|
      view.feed_filters.create :feed_id => feed_filter.feed_id, :state => feed_filter.state
    end
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
    self.class.arg_to_tag(arg)
  end
  
  def arg_to_feed(arg)
    self.class.arg_to_feed(arg)
  end

  def self.arg_to_tag(arg)
    if arg.is_a?(Tag)
      arg.id
    elsif arg.to_s =~ /^\d+$/
      arg.to_i
    else
      raise ArgumentError.new("Argument must be a tag or tag id but was #{arg.inspect}")
    end
  end
  
  def self.arg_to_feed(arg)
    if arg.is_a?(Feed)
      arg.id
    elsif arg.to_s =~ /^\d+$/
      arg.to_i
    else
      raise ArgumentError.new("Argument must be a feed or feed id but was #{arg.inspect}")
    end
  end
end
