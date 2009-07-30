# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a Feed provided by an RSS/Atom source.
#
# This class includes methods for:
#
# * Finding feeds based on filters.
class Feed < ActiveRecord::Base
  belongs_to :duplicate, :class_name => 'Feed'
  has_many	:feed_items, :dependent => :delete_all

  named_scope :non_duplicates, :conditions => "feeds.duplicate_id IS NULL"

  named_scope :matching, lambda { |q|
    conditions = %w[feeds.title feeds.via feeds.alternate].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  named_scope :by, lambda { |order, direction, excluder|
    orders = {
      "title"            => "feeds.title",
      "created_on"       => "feeds.created_on",
      "updated_on"       => "feeds.updated_on",
      "feed_items_count" => "feeds.feed_items_count",
      "globally_exclude" => sanitize_sql(["NOT EXISTS(SELECT 1 FROM feed_exclusions WHERE feeds.id = feed_exclusions.feed_id AND feed_exclusions.user_id = ?)", excluder])
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
    scope = non_duplicates.by(options[:order], options[:direction], options[:excluder])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(:limit => options[:limit], :offset => options[:offset])
  end
  
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
    raise ActiveRecord::RecordNotSaved, I18n.t("winnow.errors.atom.missing_entry_id") unless entry.id
    
    unless feed = Feed.find_by_uri(entry.id)
      feed = Feed.new
      feed.uri = entry.id
    end
    
    feed.update_from_atom(entry)    
    feed
  end

  def update_from_atom(entry)
    if uri != entry.id
      raise ArgumentError, I18n.t("winnow.errors.atom.wrong_entry_id", :uri => uri, :entry_id => entry.id)
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
  def self.parse_id_uri(entry)
    begin
      uri = URI.parse(entry.id)
    
      if uri.fragment.nil?
        raise ActiveRecord::RecordNotSaved, I18n.t("winnow.errors.atom.missing_fragment", :entry_id => entry.id)
      end
    
      uri.fragment.to_i
    rescue ActiveRecord::RecordNotSaved => e
      raise e
    rescue
      raise ActiveRecord::RecordNotSaved, I18n.t("winnow.errors.atom.invalid_entry_id", :entry_id => entry.id)
    end
  end  
end
