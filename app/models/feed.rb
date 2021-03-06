# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Represents a Feed provided by an RSS/Atom source.
class Feed < ActiveRecord::Base
  # If a feed has a duplicate, then THIS feed is the duplicate
  # that is not being used.
  belongs_to :duplicate, :class_name => 'Feed'
  has_many	:feed_items
  
  # See the definition of these methods below to learn about each of these callbacks
  before_save :set_title
  before_save :set_sort_title

  named_scope :non_duplicates, :conditions => "feeds.duplicate_id IS NULL"

  # Matches the given value against any of the listed attributes.
  named_scope :matching, lambda { |q|
    conditions = %w[feeds.title feeds.via feeds.alternate].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  # Orders the results by the given order and direction. If no order is given or one is given but
  # is not one of the known orders, the default order is used. Likewise for direction.
  named_scope :by, lambda { |order, direction, excluder|
    orders = {
      "title"            => "feeds.sort_title",
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

    multi_order = [orders[order], directions[direction]].join(" ")
    multi_order << ", feeds.sort_title ASC" if order == "globally_exclude"
    
    { :order => multi_order }
  }
  
  def self.search(options = {})
    scope = non_duplicates.by(options[:order], options[:direction], options[:excluder])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(:limit => options[:limit], :offset => options[:offset])
  end
  
  # TODO: Not used - remove it
  def self.find_or_create_from_atom(atom_feed)
    feed = find_or_create_from_atom_entry(atom_feed)
    
    atom_feed.each_entry(:paginate => true) do |entry|
      feed.feed_items.find_or_create_from_atom(entry)
    end
    
    feed.save!
    feed.feed_items(:reload)
    feed
  end
  
  # Takes an atom entry containing feed metadata and either
  # finds the local feed with the matching id and updates it
  # or creates a new feed with that metadata.
  def self.find_or_create_from_atom_entry(entry)
    raise ActiveRecord::RecordNotSaved, I18n.t("winnow.errors.atom.missing_entry_id") unless entry.id
    
    unless feed = Feed.find_by_uri(entry.id)
      feed = Feed.new
      feed.uri = entry.id
    end
    
    feed.update_from_atom(entry)    
    feed
  end

  # Updates self with metadata in the atom entry.
  def update_from_atom(entry)
    if uri != entry.id
      raise ArgumentError, I18n.t("winnow.errors.atom.wrong_entry_id", :uri => uri, :entry_id => entry.id)
    else
      # Duplicate identification uses the custom link 
      duplicate_id = if duplicate_link = entry.links.detect {|l| l.rel == "http://peerworks.org/duplicateOf"}
        Feed.find_by_uri(duplicate_link.href).id rescue nil
      end
      
      self.attributes = {
        :title      => entry.title,
        :updated    => entry.updated,
        :alternate  => (entry.alternate and entry.alternate.href),
        :via        => (entry.via and entry.via.href),
        :collector_link => (entry.self and entry.self.href),
        :duplicate_id => duplicate_id
      }

      self.save!
    
      self
    end
  end
  
  # Only destroy feeds that have no items.
  #
  def before_destroy
    self.feed_items.count == 0
  end
  
  # Override destroy so we can delete the feed items in a separate transaction.
  # This allows us to delete feed items without manual taggings, leaving manually
  # tagged feed items in place. A feed will only be deleted if all it's items
  # can be deleted, the +before_destroy+ method ensures this.
  #
  # See #1072.
  #
  def destroy
    Feed.transaction do
      Feed.transaction(:requires_new => :true) do
        self.feed_items.each {|item| item.destroy }
      end
      super
    end
  end
  
private
  # The title should be set to the host of the alternate of via 
  # urls if a title does not exist.
  def set_title
    return if title.present?

    if alternate.present?
      self.title = URI.parse(alternate).host
    elsif via.present?
      self.title = URI.parse(via).host
    end
  end

  # The sort_title should remove leading articles, remove non-alphanumeric
  # characters, and downcase the title.
  def set_sort_title
    self.sort_title = title.to_s.downcase.gsub(/^(a|an|the) /, '').gsub(/[^a-zA-Z0-9]/, '')
  end
end
