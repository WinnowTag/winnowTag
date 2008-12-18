# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a Feed provided by an RSS/Atom source.
#
# A Feed mainly handles collection of new items through the
# collect and collect_all methods. It also provides a way to
# get a list of feeds with item counts after applying similar
# filters to those used by FeedItem.find_with_filters.
class Feed < ActiveRecord::Base
  belongs_to :duplicate, :class_name => 'Feed'
  has_many	:feed_items, :dependent => :delete_all
  # TODO: localization
  validates_uniqueness_of :via, :message => 'Feed already exists'
  alias_attribute :name, :title
  before_save :update_sort_title

  def self.find_or_create_from_atom(atom_feed)
    feed = find_or_create_from_atom_entry(atom_feed)
    
    atom_feed.each_entry(:paginate => true) do |entry|
      feed.feed_items.find_or_create_from_atom(entry)
    end
    
    feed.save!
    feed.feed_items(:reload)
    feed
  end
  
  def self.find_or_create_from_atom_entry(entry)
    # TODO: localization
    raise ActiveRecord::RecordNotSaved, "Atom::Entry is missing id" if entry.id.nil?
    
    unless feed = Feed.find_by_uri(entry.id)
      feed = Feed.new
      feed.uri = entry.id
    end
    
    feed.update_from_atom(entry)    
    feed
  end
  
  named_scope :non_duplicates, :conditions => "feeds.duplicate_id IS NULL"
  
  named_scope :matching, lambda { |q|
    { :conditions => ["(feeds.title LIKE :q OR feeds.alternate LIKE :q)", { :q => "%#{q}%" }] }
  }
  
  named_scope :by, lambda { |order, direction|
    orders = {
      "title" => "feeds.title",
      "created_on" => "feeds.created_on",
      "updated_on" => "feeds.updated_on",
      "feed_items_count" => "feeds.feed_items_count",
      "globally_exclude" => "globally_exclude"
    }
    orders.default = "feeds.title"
    
    directions = {
      "asc" => "ASC",
      "desc" => "DESC"
    }
    directions.default = "ASC"
    
    { :order => [orders[order], directions[direction]].join(" ") }
  }
  
  def self.search(options = {})
    scope = non_duplicates.by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
  
    select = ["feeds.*"]
    if options[:excluder]
      select << "NOT EXISTS(SELECT 1 FROM feed_exclusions WHERE feeds.id = feed_exclusions.feed_id AND feed_exclusions.user_id = #{options[:excluder].id}) AS globally_exclude"
    end

    scope.all(:select => select.join(", "), :limit => options[:limit], :offset => options[:offset])
  end
  
  def self.find_by_url_or_link(url)
    self.find(:first, :conditions => ['url = ? or link = ?', url, url])
  end
  
  def update_from_atom(entry)
    if self.uri != entry.id
      # TODO: localization
      raise ArgumentError, "Tried to update feed (#{self.uri}) from entry with different id: #{entry.id}"
    else
      duplicate_id = if duplicate_link = entry.links.detect {|l| l.rel == "http://peerworks.org/duplicateOf"}
        Feed.find_by_uri(duplicate_link.href).id rescue nil
      end
      
      self.attributes = {
        :title      => (entry.title or ''),
        :updated    => entry.updated,
        :alternate  => (entry.alternate and entry.alternate.href),
        :via        => (entry.via and entry.via.href),
        :collector_link => (entry.self and entry.self.href),
        :duplicate_id => duplicate_id
      }

      self.save!
      
      if duplicate_id
        FeedSubscription.update_all("feed_id = #{duplicate_id}", "feed_id = #{self.id}")        
      end
    
      self
    end
  end
  
  def title
    if not read_attribute(:title).blank?
      read_attribute(:title)
    elsif not alternate.blank?
      URI.parse(alternate).host
    elsif not via.blank?
      URI.parse(via).host
    end
  end
  
private
  def update_sort_title
    self.sort_title = read_attribute(:title) && read_attribute(:title).downcase
  end  
end
