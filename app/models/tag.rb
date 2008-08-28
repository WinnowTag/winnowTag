# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
  has_many :comments
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
  
  def classifier_count
    feed_items_count.to_i - positive_count.to_i - negative_count.to_i
  end
  
  def inspect
    "<Tag name=#{name}, user=#{user.login}>"
  end
  
  # Provides the natural ordering of tags and their case-insensitive lexical ordering.
  def <=>(other)
    if other.is_a? Tag
      self.name.downcase <=> other.name.downcase
    else
      # TODO: localization
      raise ArgumentError, "Cannot compare Tag to #{other.class}"
    end
  end
  
  def last_trained
    if last_trained = read_attribute(:last_trained)
      Time.parse(last_trained)
    else
      if tagging = taggings.find(:first, :conditions => ['classifier_tagging = ?', false], :order => 'created_on DESC')
        tagging.created_on
      end
    end
  end
  
  def copy(to)
    if self == to 
      # TODO: localization
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    if to.taggings.size > 0
      # TODO: localization
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
      # TODO: localization
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
    Tagging.delete_all("classifier_tagging = 1 AND tag_id = #{self.id}")
  end
  
  def potentially_undertrained?
    self.positive_taggings.size < Tag.undertrained_threshold
  end
      
  # This needs to be fast so we'll bypass Active Record
  def taggings_from_atom(atom)
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
    
    connection.execute("UPDATE tags SET last_classified_at = '#{Time.now.getutc.to_formatted_s(:db)}' where id = #{self.id}")
  end
  
  private :taggings_from_atom
  
  def create_taggings_from_atom(atom)
    Tagging.transaction do 
      taggings_from_atom(atom)
    end
  end
  
  def replace_taggings_from_atom(atom)
    Tagging.transaction do
      self.delete_classifier_taggings!
      taggings_from_atom(atom)      
    end
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
      feed.categories << Atom::Category.new(:term => self.name, :scheme => "#{options[:base_uri]}/#{user.login}/tags/")
      
      feed.links << Atom::Link.new(:rel => "alternate", :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom"))
      feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/edit", 
                                   :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/classifier_taggings.atom"))
                         
      conditions = []
      condition_values = []
                
      if options[:training_only]
        conditions << 'classifier_tagging = 0'
        feed.links << Atom::Link.new(:rel => "self", :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom"))
      else
        conditions << 'strength <> 0'
        feed.links << Atom::Link.new(:rel => "self", 
                                     :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom"))
        feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/training", 
                                     :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom"))     
      end
      
      if options[:since]
        conditions << 'taggings.created_on > ?'
        condition_values << options[:since].getutc
      end
      
      self.taggings.find(:all, :conditions => [conditions.join(" and "), *condition_values], :limit => (options[:limit] or 100),
                               :order => 'feed_items.updated DESC', :include => [{:feed_item, :content}]).each do |tagging|
        feed.entries << tagging.feed_item.to_atom(options.merge({:include_tags => self, :training_only => options[:training_only]}))
      end
    end
  end
  
  def self.to_atom(options = {})
    Atom::Feed.new do |feed|
      feed.title = "Winnow tags"
      feed.updated = Tag.maximum(:created_on)
        
      Tag.find(:all, :include => :user).each do |tag|
        feed.entries << Atom::Entry.new do |entry|
          entry.title = tag.name
          entry.id    = "#{options[:base_uri]}/#{tag.user.login}/tags/#{tag.name}"
          entry.updated = tag.updated_on
          entry.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/training", 
                                        :href => URI.escape("#{options[:base_uri]}/#{tag.user.login}/tags/#{tag.name}/training.atom"))
        end
      end
    end
  end
  
  def self.search(options = {})
    select = ['tags.*', 
              '(SELECT COUNT(*) FROM comments WHERE comments.tag_id = tags.id) AS comments_number',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
              '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count',
              '(SELECT MAX(taggings.created_on) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0) AS last_trained',
              "CASE " <<
                "WHEN EXISTS(SELECT 1 FROM tag_subscriptions WHERE tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = #{options[:user].id}) THEN 0 " <<
                "WHEN EXISTS(SELECT 1 FROM tag_exclusions WHERE tags.id = tag_exclusions.tag_id AND tag_exclusions.user_id = #{options[:user].id}) THEN 1 " <<
                "ELSE 2 END AS state"]
    
    joins = ["LEFT JOIN users ON tags.user_id = users.id"]

    conditions, values = [], []
    if options[:conditions]
      conditions << sanitize_sql(options[:conditions])
    end

    if options[:own]
      joins << "LEFT JOIN tag_subscriptions ON tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = #{options[:user].id}"
      joins << "LEFT JOIN tag_exclusions ON tags.id = tag_exclusions.tag_id AND tag_exclusions.user_id = #{options[:user].id}"
      conditions << "(tags.user_id = ? OR tag_subscriptions.id IS NOT NULL OR tag_exclusions.id IS NOT NULL)"
      values << options[:user].id
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
    when "state", "comments_number", "positive_count", "negative_count", "last_trained"
      options[:order]
    when "classifier_count"
      "(feed_items_count - positive_count - negative_count)"
    when "login"
      "users.#{options[:order]}"
    else
      "tags.name"
    end
    
    case options[:direction]
    when "asc", "desc"
      order = "#{order} #{options[:direction].upcase}"
    end

    options_for_find = { :joins => joins.join(" "), :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values] }
    
    results = find(:all, options_for_find.merge(:select => select.join(","),
                   :order => order, :group => "tags.id", :limit => options[:limit], :offset => options[:offset]))
    
    if options[:count]
      [results, count(options_for_find)]
    else
      results
    end
  end
end
