# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

def Tag(user, tag)
  if tag.nil? || tag.is_a?(Tag) 
    tag
  else
    Tag.find_or_create_by_user_id_and_name(user.id, tag)    
  end
end

require 'atom'
require 'atom/pub'

# Tag is a simple word used to tag an item. Every Tagging belongs to a Tag.
# 
# == Schema Information
# Schema version: 57
#
# Table name: tags
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

class Tag < ActiveRecord::Base  
  cattr_accessor :undertrained_threshold
  @@undertrained_threshold = 6
  
  has_many :taggings, :dependent => :delete_all
  has_many :positive_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ? and strength = ?', false, 1]
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true], 
            :dependent => :delete_all
  has_many :feed_items, :through => :taggings
  has_many :tag_subscriptions
  belongs_to :user
  validates_uniqueness_of :name, :scope => :user_id
  validates_presence_of :name
  
  # Returns a suitable label for the classification UI display.
  def classification_label
    truncate(self.name, 15)
  end
  
  # Returns JSON representation of the tag.
  def to_json
    self.name.to_json
  end
  
  # Gets a string representation of the tag.
  def to_s
    self.name
  end
  
  # Gets a parameter representation of the tag.
  # def to_param
  #   self.name
  # end
  
  def inspect
    "<Tag name=#{name}, user=#{user.login}>"
  end
  
  # Provides the natural ordering of tags and their case-insensitive lexical ordering.
  def <=>(other)
    if other.is_a? Tag
      self.name.downcase <=> other.name.downcase
    else
      raise ArgumentError, "Cannot compare Tag to #{other.class}"
    end
  end
  
  def last_used_by
    if last_used_by = read_attribute(:last_used_by)
      Time.parse(last_used_by)
    else
      if tagging = taggings.find(:first, :order => 'created_on DESC')
        tagging.created_on
      end
    end
  end
  
  def copy(to)
    if self == to 
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    if to.taggings.size > 0
      raise ArgumentError, "Target tagger already has a #{to.name} tag"
    end
    
    self.manual_taggings.each do |tagging|
      to.user.taggings.create!(:tag => to, :feed_item_id => tagging.feed_item_id, :strength => tagging.strength, :user_id => to.user_id)
    end
    
    to.bias = self.bias    
    to.comment = self.comment
    to.save!
  end
  
  def merge(to)
    if self == to 
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    self.manual_taggings.each do |tagging|
      unless to.manual_taggings.exists?(['feed_item_id = ?', tagging.feed_item_id])
        to.user.taggings.create!(:tag => to, :feed_item_id => tagging.feed_item_id, :strength => tagging.strength)
      end
    end
    
    destroy
  end
  
  def overwrite(to)
    to.taggings.clear
    self.copy(to)
  end
    
  def delete_classifier_taggings!
    Tagging.delete_all("classifier_tagging = 1 and tag_id = #{self.id}")
  end
  
  def potentially_undertrained?
    self.positive_taggings.size < Tag.undertrained_threshold
  end
  
  CLASSIFIER_NAMESPACE = 'http://peerworks.org/classifier' unless defined?(CLASSIFIER_NAMESPACE)
  
  # This needs to be fast so we'll bypass Active Record
  def create_taggings_from_atom(atom)
    Tagging.transaction do 
      atom.entries.each do |entry|
        begin
          item_id = URI.parse(entry.id).fragment.to_i
          strength = if category = entry.categories.detect {|c| c.term == self.name && c.scheme =~ %r{/#{self.user.login}/tags/$}}
            category[CLASSIFIER_NAMESPACE, 'strength'].first.to_f
          else 
            0.0
          end
          
          if strength >= 0.9
            connection.execute "INSERT IGNORE INTO taggings " +
                                "(feed_item_id, tag_id, user_id, classifier_tagging, strength, created_on) " +
                                "VALUES(#{item_id}, #{self.id}, #{self.user_id}, 1, #{strength}, UTC_TIMESTAMP()) " +
                                "ON DUPLICATE KEY UPDATE strength = VALUES(strength);"
          end
        rescue URI::InvalidURIError => urie
          logger.warn "Invalid URI in Tag Assignment Document: #{entry.id}"
        rescue ActiveRecord::StatementInvalid => arsi
          logger.warn "Invalid taggings statement for #{entry.id}, probably the item doesn't exist."
        end
      end
    end
  end
  
  def replace_taggings_from_atom(atom)
    self.classifier_taggings.clear
    self.create_taggings_from_atom(atom)
  end
  
  # Return an Atom document for this tag.
  #
  # When :training_only => true all and only training examples will be included
  # in the document and it will conform to the Training Definition Document.
  #
  def to_atom(options = {})
    Atom::Feed.new do |feed|
      feed.title = "#{self.user.login}:#{self.name}"
      feed.id = "#{options[:base_uri]}/#{user.login}/tags/#{self.name}"
      feed.updated = self.updated_on
      feed[CLASSIFIER_NAMESPACE, 'classified'] << self.last_classified_at.xmlschema if self.last_classified_at
      feed[CLASSIFIER_NAMESPACE, 'bias'] << self.bias.to_s
      
      feed.links << Atom::Link.new(:rel => "alternate", :href => "#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom")
      feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/edit", 
                                   :href => "#{options[:base_uri]}/#{user.login}/tags/#{self.name}/classifier_taggings.atom")
                         
      conditions = []
      condition_values = []
                
      if options[:training_only]
        conditions << 'classifier_tagging = 0'
        feed.links << Atom::Link.new(:rel => "self", :href => "#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom")
      else
        conditions << 'strength <> 0'
        feed.links << Atom::Link.new(:rel => "self", 
                                     :href => "#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom")
        feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/training", 
                                     :href => "#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom")        
      end
      
      if options[:since]
        conditions << 'feed_items.updated > ?'
        condition_values << options[:since].getutc
      end
      
      self.taggings.find(:all, :conditions => [conditions.join(" and "), *condition_values], 
                               :order => 'feed_items.updated DESC', :include => [{:feed_item, :content}]).each do |tagging|
        entry = tagging.feed_item.to_atom(options)
        
        if tagging.strength > 0.9
          entry.categories << Atom::Category.new do |cat|
            cat.term = self.name
            cat.scheme = "#{options[:base_uri]}/#{user.login}/tags/"
            if tagging.classifier_tagging?
              cat[CLASSIFIER_NAMESPACE, 'strength'] << tagging.strength.to_s
              cat[CLASSIFIER_NAMESPACE, 'strength'].as_attribute = true
            end
          end
        elsif tagging.strength == 0            
          entry.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/negative-example", :href => feed.id)
        end
        
        feed.entries << entry
      end
    end
  end
  
  def self.to_atomsvc(options = {})
    Atom::Pub::Service.new do |service|
      service.workspaces << Atom::Pub::Workspace.new  do |wkspc|
        wkspc.title = "Tag Training"
        Tag.find(:all).each do |tag|
          wkspc.collections << Atom::Pub::Collection.new do |collection|
            collection.title = tag.name
            collection.href = "#{options[:base_uri]}/tags/#{tag.id}/training"
            collection.accepts << ''
          end
        end
      end
    end
  end
  
  def self.search(options = {})
    joins = ["LEFT JOIN users ON tags.user_id = users.id"]
    if options[:subscribed_by]
      joins << "INNER JOIN tag_subscriptions ON tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = #{options[:subscribed_by].id}"
    end
    
    select = ['tags.*', 
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND classifier_tagging = 1 AND NOT EXISTS' <<
                '(SELECT 1 FROM taggings manual_taggings WHERE manual_taggings.tag_id = taggings.tag_id AND ' <<
                  'manual_taggings.feed_item_id = taggings.feed_item_id AND manual_taggings.classifier_tagging = 0)) AS classifier_count',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND classifier_tagging = 0) AS training_count',
              '(SELECT MAX(taggings.created_on) FROM taggings WHERE taggings.tag_id = tags.id) AS last_used_by']
    if options[:excluder]
      select << "((SELECT COUNT(*) FROM tag_exclusions WHERE tags.id = tag_exclusions.tag_id AND tag_exclusions.user_id = #{options[:excluder].id}) > 0) AS globally_exclude"
    else
      select << "0 AS globally_exclude"
    end
    if options[:subscriber]
      select << "((SELECT COUNT(*) FROM tag_subscriptions WHERE tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = #{options[:subscriber].id}) > 0) AS subscribe"
    else
      select << "0 AS subscribe"
    end
    
    conditions, values = [], []
    if options[:conditions]
      conditions << sanitize_sql(options[:conditions])
    end
    
    if !options[:text_filter].blank?
      ored_conditions = []
      ored_conditions << "LOWER(tags.name) LIKE LOWER(?)"
      ored_conditions << "LOWER(tags.comment) LIKE LOWER(?)"
      ored_conditions << "LOWER(users.login) LIKE LOWER(?)"
      conditions << "(#{ored_conditions.join(" OR ")})"
      
      value = "%#{options[:text_filter]}%"
      values << value << value << value
    end
    
    order = case options[:order]
    when "name", "public", "id"
      "tags.#{options[:order]}"
    when "subscribe", "training_count", "classifier_count", "last_used_by", "globally_exclude"
      options[:order]
    when "login"
      "users.#{options[:order]}"
    else
      "tags.name"
    end
    
    case options[:direction]
    when "asc", "desc"
      order = "#{order} #{options[:direction].upcase}"
    end

    options_for_find = { :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values] }
    
    results = find(:all, options_for_find.merge(:select => select.join(","),  :joins => joins.join(" "),
                   :order => order, :group => "tags.id", :limit => options[:limit], :offset => options[:offset]))
    
    if options[:count]
      [results, count(options_for_find)]
    else
      results
    end
  end
end
