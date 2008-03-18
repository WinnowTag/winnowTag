# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Represents a Feed provided by an RSS/Atom source.
#
# A Feed mainly handles collection of new items through the
# collect and collect_all methods. It also provides a way to
# get a list of feeds with item counts after applying similar
# filters to those used by FeedItem.find_with_filters.
#
#
# == Schema Information
# Schema version: 57
#
# Table name: feeds
#
#  id                :integer(11)   not null, primary key
#  url               :string(255)   
#  title             :string(255)   
#  link              :string(255)   
#  last_http_headers :text          
#  updated_on        :datetime      
#  active            :boolean(1)    default(TRUE)
#  created_on        :datetime      
#  sort_title        :string(255)   
#

class Feed < ActiveRecord::Base
  belongs_to :duplicate, :class_name => 'Feed'
  has_many	:feed_items, :dependent => :delete_all
  validates_uniqueness_of :via, :message => 'Feed already exists'
  alias_attribute :name, :title
  before_save :update_sort_title

  def self.find_or_create_from_atom(atom_feed)
    feed = find_or_create_from_atom_entry(atom_feed)
    
    atom_feed.each_entry(:paginate => true) do |entry|
      feed.feed_items.find_or_create_from_atom(entry)
    end
    
    feed.save!
    feed
  end
  
  def self.find_or_create_from_atom_entry(entry)
    raise ActiveRecord::RecordNotSaved, "Atom::Entry is missing id" if entry.id.nil?
    id = parse_id_uri(entry)
    
    unless feed = Feed.find_by_id(id)
      feed = Feed.new
      feed.id = id
    end
    
    feed.update_from_atom(entry)    
    feed
  end
  
  def self.search options = {}
    joins = []
    conditions, values = ['duplicate_id is ?'], [nil]
    
    if options[:subscribed_by]
      joins << "INNER JOIN feed_subscriptions ON feeds.id = feed_subscriptions.feed_id AND feed_subscriptions.user_id = #{options[:subscribed_by].id}"
    end
    
    unless options[:search_term].blank?
      conditions << '(title LIKE ? OR alternate LIKE ?)'
      values << "%#{options[:search_term]}%" << "%#{options[:search_term]}%"
    end
  
    select = ["feeds.*"]
    if options[:excluder]
      select << "((SELECT COUNT(*) FROM feed_exclusions WHERE feeds.id = feed_exclusions.feed_id AND feed_exclusions.user_id = #{options[:excluder].id}) > 0) AS globally_exclude"
    end
    
    paginate(:select => select.join(","),
             :joins => joins.join(" "),
             :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values],
             :page => options[:page],
             :group => "feeds.id",
             :order => options[:order])
  end
  
  def self.find_by_url_or_link(url)
    self.find(:first, :conditions => ['url = ? or link = ?', url, url])
  end
  
  def update_from_atom(entry)
    if self.id != self.class.parse_id_uri(entry)
      raise ArgumentError, "Tried to update feed attributes from entry with different id"
    else
      self.attributes = {
        :title      => (entry.title or ''),
        :updated    => entry.updated,
        :published  => entry.published,
        :alternate  => (entry.alternate and entry.alternate.href),
        :via        => (entry.via and entry.via.href),
        :collector_link => (entry.self and entry.self.href)
      }
    
      self.save!
      self
    end
  end
  
  def title
    unless read_attribute(:title).blank?
      read_attribute(:title)
    else
      URI.parse(via).host
    end
  end
  
private
  def update_sort_title
    self.sort_title = read_attribute(:title) && read_attribute(:title).downcase
  end
  
  def self.parse_id_uri(entry)
    begin
      uri = URI.parse(entry.id)
    
      if uri.fragment.nil?
        raise ActiveRecord::RecordNotSaved, "Atom::Entry id is missing fragment: '#{entry.id}'"
      end
    
      uri.fragment.to_i
    rescue ActiveRecord::RecordNotSaved => e
      raise e
    rescue 
      raise ActiveRecord::RecordNotSaved, "Atom::Entry has missing or invalid id: '#{entry.id}'" 
    end
  end  
end
