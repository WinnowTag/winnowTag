# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Provides a representation of an item from an RSS/Atom feed.
#
# This class includes methods for:
#
# * Finding items based on taggings and other filters.
# * Extracting an item from a <tt>FeedTools::Item</tt> object.
# * Getting and producing the tokens for a feed item.
#
# The +FeedItem+ class only stores summary metadata for a feed item, the actual
# content is stored in the +FeedItemContent+ class. This enables faster database
# access on the smaller summary records and allows us to use a MyISAM table for
# the content which can then be index using MySQL's Full Text Indexing.
#
# Tokens are stored in a +FeedItemTokensContainer+.
#
# See also +FeedItemContent+ and +FeedItemTokensContainer+.
class FeedItem < ActiveRecord::Base
  acts_as_readable
  
  attr_readonly :uri
  attr_accessor :taggings_to_display

  validates_presence_of :link
  validates_uniqueness_of :link, :case_sensitive => false
  belongs_to :feed, :counter_cache => true
  has_one :content, :dependent => :delete, :class_name => 'FeedItemContent'
  has_one :text_index, :dependent => :delete, :class_name => 'FeedItemTextIndex'
  has_many :taggings
  
  has_many :tags, :through => :taggings  
  
  def self.find_or_create_from_atom(entry, options = {})
    raise ActiveRecord::RecordNotSaved, I18n.t("winnow.errors.atom.missing_entry_id") unless entry.id
    
    unless item = FeedItem.find_by_uri(entry.id)
      item = FeedItem.new
      item.uri = entry.id
    end
    
    if item.new_record? || options[:update]
      item.update_from_atom(entry)
      item.save!
    end
    
    item
  end
  
  def update_from_atom(entry)
    raise ArgumentError, I18n.t("winnow.errors.atom.wrong_entry_id", :uri => uri, :entry_id => entry.id) if uri != entry.id
    
    self.attributes = {
      :title   => (entry.title or I18n.t("winnow.defaults.feed_item.title")),
      :link    => (entry.alternate and entry.alternate.href),
      :author  => (entry.authors.empty? ? nil : entry.authors.first.name),
      :updated => entry.updated,
      :collector_link => (entry.self and entry.self.href)
    }
    
    self.content = FeedItemContent.new(:content => entry.content.to_s)
    
    self.save!
    self
  end
  
  def to_atom(options = {})
    Atom::Entry.new do |entry|
      entry.title = self.title
      entry.id = self.uri
      entry.updated = self.updated
      entry.authors << Atom::Person.new(:name => self.author) if self.author
      entry.links << Atom::Link.new(:rel => 'self', :href => self.collector_link)
      entry.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      entry.links << Atom::Link.new(:rel => 'http://peerworks.org/feed', :href => "urn:peerworks.org:feed##{self.id}")
      
      entry.source = Atom::Source.new do |source|
        source.title = self.feed.title
        source.links << Atom::Link.new(:rel => 'self', :href => self.feed.via) if self.feed.via
        source.links << Atom::Link.new(:rel => 'alternate', :href => self.feed.alternate) if self.feed.alternate
      end if self.feed
      
      if self.content
        begin
          entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'utf-8', self.content.content).first)
        rescue Iconv::IllegalSequence, Iconv::InvalidCharacter
          entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'LATIN1', self.content.content).first)
        end
      end
      
      if options[:include_tags]
        include_tags = Array(options[:include_tags])
        
        self.taggings.select {|t| include_tags.include?(t.tag) && (!t.classifier_tagging? || !options[:training_only])}.each do |tagging|
          if tagging.strength > 0.9
            entry.categories << Atom::Category.new do |cat|
              cat.term = tagging.tag.name
              cat.scheme = "#{options[:base_uri]}/#{tagging.tag.user.login}/tags/"
              if tagging.classifier_tagging?
                cat[CLASSIFIER_NAMESPACE, 'strength'] << tagging.strength.to_s
                cat[CLASSIFIER_NAMESPACE, 'strength'].as_attribute = true
              end
            end
          elsif tagging.strength == 0            
            entry.links << Atom::Link.new(:rel  => "#{CLASSIFIER_NAMESPACE}/negative-example", 
                                          :href => "#{options[:base_uri]}/#{tagging.tag.user.login}/tags/#{tagging.tag.name}")
          end
        end
      end
    end
  end
  
  # Destroy feed items older than +since+.
  #
  # This also deletes all classifier taggings that are on items older than +since+,
  # Manual taggings are untouched.
  #
  # You could do this in the one SQL statement, however using ActiveRecord,
  # while taking slightly longer, will break this up into multiple transactions
  # and reduce the chance of getting a deadlock with a long transaction.
  def self.archive_items(since = 30.days.ago.getutc)
    taggings_deleted = Tagging.delete_all(['classifier_tagging = ? and feed_item_id IN (select id from feed_items where updated < ?)', true, since])
    conditions = ['updated < ? and NOT EXISTS (select feed_item_id from taggings where feed_item_id = feed_items.id)', since]
    counter = 0
    FeedItem.find_each(:conditions => conditions) do |item|
      item.destroy
      counter += 1
    end
    logger.info("ARCHIVAL: Deleted #{counter} items and #{taggings_deleted} classifier taggings older than #{since}")
  end
  
  def self.atom_with_filters(filters = {})
    base_uri = filters.delete(:base_uri)
    self_link = filters.delete(:self_link)
    alt_link = filters.delete(:alt_link)
    items = self.find_with_filters(filters)

    tags = filters[:tag_ids].to_s.split(",").map {|id| Tag.find(id) }.map { |t| "'#{t.name}'" }
    feeds = filters[:feed_ids].to_s.split(",").map {|id| Feed.find(id) }.map { |f| "'#{f.title}'" }
    text_filter = filters[:text_filter]
    mode = filters[:mode]

    title = if feeds.present? && tags.present? && text_filter.present?
      I18n.t("winnow.feeds.feed_item.mode_feeds_tags_text_filter", :mode => mode, :feeds => feeds.to_sentence, :tags => tags.to_sentence, :text_filter => text_filter)
    elsif feeds.present? && tags.present?
      I18n.t("winnow.feeds.feed_item.mode_feeds_tags", :mode => mode, :feeds => feeds.to_sentence, :tags => tags.to_sentence)
    elsif feeds.present? && text_filter.present?
      I18n.t("winnow.feeds.feed_item.mode_feeds_text_filter", :mode => mode, :feeds => feeds.to_sentence, :text_filter => text_filter)
    elsif tags.present? && text_filter.present?
      I18n.t("winnow.feeds.feed_item.mode_tags_text_filter", :mode => mode, :tags => tags.to_sentence, :text_filter => text_filter)
    elsif feeds.present?
      I18n.t("winnow.feeds.feed_item.mode_feeds", :mode => mode, :feeds => feeds.to_sentence)
    elsif tags.present?
      I18n.t("winnow.feeds.feed_item.mode_tags", :mode => mode, :tags => tags.to_sentence)
    elsif text_filter.present?
      I18n.t("winnow.feeds.feed_item.mode_text_filter", :mode => mode, :text_filter => text_filter)
    else
      I18n.t("winnow.feeds.feed_item.mode", :mode => mode)
    end

    feed = Atom::Feed.new do |feed|
      feed.title = title
      feed.id = self_link
      feed.updated = items.first.updated if items.first
      feed.links << Atom::Link.new(:rel => 'self', :href => self_link)
      feed.links << Atom::Link.new(:rel => 'alternate', :href => alt_link);
      items.each do |feed_item|            
        feed.entries << feed_item.to_atom(:base_uri => base_uri, :include_tags => filters[:user].tags + filters[:user].subscribed_tags)
      end
    end
  end  
  
  # Performs a <tt>find(:all)</tt> using the options generated by passing the +filters+ argument to 
  # +options_for_filters+.
  #
  # When a user is provided in the +filters+ hash this method will also do some prefetching of
  # the user and classifier taggings for the items loaded. This uses the caching mechanism
  # provided by the +FindByTagger+ module.  The advantage of this is that you no longer need 
  # N + 1 queries to get the taggings for each item, instead there are just 3 queries, one 
  # to get the items and one each to get the taggings for the user and user's classifier.
  #
  # Note: The Rails eager loading mechanism can't substitute for this custom solution because
  # of the complexity of the joining in the query produced by +options_with_filters+.
  #
  def self.find_with_filters(filters = {})    
    user = filters[:user]
    
    options_for_find = options_for_filters(filters).merge(:select => [
      'feed_items.*', 'feeds.title AS feed_title', 
      "EXISTS (SELECT 1 FROM readings WHERE readings.readable_type = 'FeedItem' AND readings.readable_id = feed_items.id AND readings.user_id = #{user.id}) AS read_by_current_user"
    ].join(","))
    options_for_find[:joins] << " LEFT JOIN feeds ON feed_items.feed_id = feeds.id"
    
    feed_items = FeedItem.find(:all, options_for_find)
    
    selected_tags = filters[:tag_ids].blank? ? [] : Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, user])
    tags_to_display = (user.sidebar_tags + user.subscribed_tags - user.excluded_tags + selected_tags).uniq
    taggings = Tagging.find(:all, 
      :include => :tag,
      :conditions => ['feed_item_id IN (?) AND tag_id IN (?)', feed_items, tags_to_display]).group_by(&:feed_item_id)

    feed_items.each do |feed_item|
      feed_item.taggings_to_display = (taggings[feed_item.id] || []).inject({}) do |hash, tagging|
        hash[tagging.tag] ||= []
        if tagging.classifier_tagging?
          hash[tagging.tag] << tagging
        else
          hash[tagging.tag].unshift(tagging)
        end
        hash
      end.to_a.sort_by { |tag, _taggings| tag.sort_name }
    end
    
    feed_items
  end

  def self.read_by!(filters)
    options_for_find = options_for_filters(filters)   

    feed_item_ids_sql = "SELECT DISTINCT #{filters[:user].id}, feed_items.id, 'FeedItem', UTC_TIMESTAMP(), UTC_TIMESTAMP() FROM feed_items"
    feed_item_ids_sql << " #{options_for_find[:joins]}" unless options_for_find[:joins].blank?
    feed_item_ids_sql << " WHERE #{options_for_find[:conditions]}" unless options_for_find[:conditions].blank?

    Reading.connection.execute "INSERT IGNORE INTO readings (user_id, readable_id, readable_type, created_at, updated_at) #{feed_item_ids_sql}"
  end
  
  def self.unread_by!(filters)
    case filters[:mode]
      when nil, "unread" then filters[:mode] = "all"
    end

    options_for_find = options_for_filters(filters)

    feed_item_ids_sql = "SELECT DISTINCT feed_items.id FROM feed_items"
    feed_item_ids_sql << " #{options_for_find[:joins]}" unless options_for_find[:joins].blank?
    feed_item_ids_sql << " WHERE #{options_for_find[:conditions]}" unless options_for_find[:conditions].blank?

    Reading.delete_all(["readings.user_id = ? AND readings.readable_type = 'FeedItem' AND readings.readable_id IN(#{feed_item_ids_sql})", filters[:user]])
  end

  # This builds the SQL to use for the +find_with_filters+ method.
  #
  # The SQL is pretty complex, I had a go at trying to find a nicer way to generate it, as opposed
  # to building up two big strings, one for join conditions and one for where conditions.  I tried
  # SQLDSL except it turned out to be just as verbose and harder to read due to all the conditionals. So I
  # have settled for string concatenation with (hopefully) good documentation.
  #
  # === Parameters
  #
  # A Hash with these keys (all optional):
  # 
  # Also supports <tt>:limit</tt>, <tt>:offset</tt> and <tt>:order</tt> as defined by <tt>ActiveRecord::Base.find</tt>
  #
  # This will return a <tt>Hash</tt> of options suitable for passing to <tt>FeedItem.find</tt>.
  # 
  def self.options_for_filters(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :offset => filters[:offset]}
    
    direction = case filters[:direction]
      when "asc", "desc"
        filters[:direction].upcase
    end
    
    options[:order] = case filters[:order]
    when "date"
      "feed_items.updated #{direction}"
    when "id"
      "feed_items.id #{direction}"
    else
      "feed_items.updated DESC"
    end

    filters[:mode] ||= "unread"

    joins = []
    add_text_filter_joins!(filters[:text_filter], joins)

    conditions = []
    add_feed_filter_conditions!(filters[:feed_ids], conditions)
    
    tags = if filters[:tag_ids]
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]])
    elsif filters[:mode] =~ /trained/i # limit the search to tagged items
      filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags
    else
      tags = []
    end
    conditions << build_tag_inclusion_filter(tags, filters[:mode])

    conditions = ["(#{conditions.compact.join(" OR ")})"] unless conditions.compact.blank? 
    
    unless filters[:mode] =~ /trained/i # don't filter excluded items when showing trained items
      conditions << build_tag_exclusion_filter(filters[:user].excluded_tags)
    end
    
    unless filters[:mode] =~ /trained/i # don't filter excluded items when showing trained items
      add_globally_exclude_feed_filter_conditions!(filters[:user].excluded_feeds, conditions)
    end
    
    if filters[:mode] =~ /unread/i # only filter out read items when showing unread items
      add_readings_filter_conditions!(filters[:user], conditions)
    end
        
    options[:conditions] = conditions.compact.blank? ? nil : conditions.compact.join(" AND ")
    options[:joins] = joins.uniq.join(" ")
    
    options
  end
  
  # Add any +text_filter+. This is done using a inner join on +feed_item_contents+ with an
  # additional join condition that applies the text filter using the full text index.
  def self.add_text_filter_joins!(text_filter, joins)
    unless text_filter.blank?
      joins << "INNER JOIN feed_item_text_indices ON feed_items.id = feed_item_text_indices.feed_item_id" +
               " AND MATCH(content) AGAINST(#{connection.quote(text_filter)} IN BOOLEAN MODE)"
    end
  end
  
  def self.add_feed_filter_conditions!(feed_ids, conditions)
    feeds = Feed.find_all_by_id(feed_ids.to_s.split(','))
    unless feeds.empty?
      conditions << "feed_items.feed_id IN (#{feeds.map(&:id).join(",")})"
    end
  end

  def self.build_tag_inclusion_filter(tags, mode)
    unless tags.empty?
      manual_taggings_sql = mode =~ /trained/i ? " AND classifier_tagging = 0" : nil
      "EXISTS (SELECT 1 FROM taggings WHERE tag_id IN(#{tags.map(&:id).join(",")}) AND feed_item_id = feed_items.id#{manual_taggings_sql})"
    end
  end

  def self.build_tag_exclusion_filter(tags)
    unless tags.empty?
      "NOT EXISTS (SELECT 1 FROM taggings WHERE tag_id IN(#{tags.map(&:id).join(",")}) AND feed_item_id = feed_items.id)"
    end
  end
  
  def self.add_globally_exclude_feed_filter_conditions!(feeds, conditions)
    unless feeds.empty?
      conditions << "feed_items.feed_id NOT IN (#{feeds.map(&:id).join(",")})"
    end
  end
  
  def self.add_readings_filter_conditions!(user, conditions)
    conditions << "NOT EXISTS (SELECT 1 FROM readings WHERE readings.user_id = #{user.id} AND readings.readable_type = 'FeedItem' AND readings.readable_id = feed_items.id)"
  end
end
