# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.

# Provides a representation of an item from an RSS/Atom feed.
#
# This class includes methods for:
#
# * Finding items based on taggings and other filters.
# * Extracting an item from a FeedTools::Item object.
# * Getting and producing the tokens for a feed item.
#
# The FeedItem class only stores summary metadata for a feed item, the actual
# content is stored in the FeedItemContent class. This enables faster database
# access on the smaller summary records and allows us to use a MyISAM table for
# the content which can then be index using MySQL's Full Text Indexing.
#
# Tokens are stored in a FeedItemTokensContainer.
#
# See also FeedItemContent and FeedItemTokensContainer.
class FeedItem < ActiveRecord::Base
  # SEARCH_OPTIONS = :options_for_filters_mysql
  # SEARCH_OPTIONS = :options_for_filters_part_ferret
  # SEARCH_OPTIONS = :options_for_filters_full_ferret
  SEARCH_OPTIONS = :options_for_filters_sphinx
  
  acts_as_ferret :fields => [:title, :real_content, :author, :tag_ids_with_spaces, :user_tag_ids_with_spaces, :feed_id, :reader_ids_with_spaces]

  # sphinx
  is_indexed :fields => [:title, :author],
             :include => [{:association_name => 'content', :field => 'content', :as => 'content'}]

  
  def real_content
    content.content if content
  end
  
  def tag_ids_with_spaces
    tag_ids.join(" ")
  end
  
  def user_tag_ids_with_spaces
    tags.from_user.map(&:id).join(" ")
  end
  
  def reader_ids_with_spaces
    reader_ids.join(" ")
  end
  
  attr_accessor :taggings_to_display

  validates_presence_of :link
  validates_uniqueness_of :link
  belongs_to :feed, :counter_cache => true
  has_one :content, :dependent => :delete, :class_name => 'FeedItemContent'
  has_one :text_index, :dependent => :delete, :class_name => 'FeedItemTextIndex'
  
  # Extends tagging associations with a find_by_tagger method.
  #
  # This also adds some trickery that allows us to cache some taggings so we can
  # load all the taggings for the current feed items into memory at once instead
  # of using a query for each feed item.
  #
  # See FeedItem.find_by_filters for how this is done.
  #
  has_many :taggings
  
  has_many :tags, :through => :taggings do
    def from_user
      find(:all, :conditions => ["taggings.classifier_tagging = ?", false])
    end
  end
  
  has_many :read_items
  has_many :readers, :through => :read_items, :source => :user
    
  # Finds some random items with their tokens.  
  #
  # Instead of using order by rand(), which is very slow for large tables,
  # we use a modified version of the method described at http://jan.kneschke.de/projects/mysql/order-by-rand/
  # to get a random set of items. The trick here is to generate a list of random ids 
  # by multiplying rand() and max(position). This list is then joined with the feed_items table
  # to get the items.  Generating this list is very fast since MySQL can do it without accessing
  # the tables or indexes at all.
  #
  # We use the position column to randomize since that is guarenteed to not have any holes
  # and to have even distribution.
  #
  def self.find_random_items_with_tokens(size)
    self.find(:all,
      :joins => "INNER JOIN random_backgrounds AS rnd ON feed_items.id = rnd.feed_item_id ",
      :limit => size)
  end
  
  def self.find_or_create_from_atom(entry)
    # TODO: localization
    raise ActiveRecord::RecordNotSaved, 'Atom::Entry missing id' if entry.id.nil?
    id = self.parse_id_uri(entry)
    
    unless item = FeedItem.find_by_id(id)
      item = FeedItem.new
      item.id = id
    end
    
    item.update_from_atom(entry)
    item.save!
    item
  end
  
  def update_from_atom(entry)
    # TODO: localization
    raise ArgumentError, "Atom entry has different id" if self.id != self.class.parse_id_uri(entry)
    
    self.attributes = {
      # TODO: localization
      :title   => (entry.title or 'Unknown Title'),
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
      entry.id = "urn:peerworks.org:entry##{self.id}"
      entry.updated = self.updated
      entry.authors << Atom::Person.new(:name => self.author)
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
        rescue Iconv::IllegalSequence
          entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'LATIN1', self.content.content).first)
        end
      end
      
      if options[:include_tags]
        include_tags = Array(options[:include_tags])
        
        self.taggings.select {|t| include_tags.include?(t.tag) }.each do |tagging|
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
    
  # Override count to use feed_id because InnoDB tables are slow with count(*)
  def self.count(*args)
    if args.first.is_a? String
      super(*args)
    elsif args.first.is_a? Hash
      super('id', args.first)
    elsif args.size == 0
      super('id', {})
    end
  end
  
  # Destroy feed items older that +since+.
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
    items = FeedItem.find(:all, :conditions => conditions)
    items.each do |item|
      item.destroy
    end
    logger.info("ARCHIVAL: Deleted #{items.size} items and #{taggings_deleted} classifier taggings older than #{since}")
  end
  
  # Gets a count of the number of items that meet conditions applied by the filters.
  #
  # See options_for_filters.
  # def self.count_with_filters(filters = {})
  #   options = options_for_filters(filters).merge(:select => "feed_items.id").except(:limit, :offset, :order)
  #   FeedItem.count(options)
  # end
  
  def self.atom_with_filters(filters = {})
    base_uri = filters.delete(:base_uri)
    self_link = filters.delete(:self_link)
    alt_link = filters.delete(:alt_link)
    @tags = filters[:tag_ids].to_s.split(",").map {|t| Tag.find(t) }
    
    feed = Atom::Feed.new do |feed|
      # TODO: localization
      feed.title = "Feed for #{@tags.to_sentence}"
      feed.id = self_link
      feed.updated = Time.now
      feed.links << Atom::Link.new(:rel => 'self', :href => self_link)
      feed.links << Atom::Link.new(:rel => 'alternate', :href => alt_link);
      self.find_with_filters(filters).each do |feed_item|            
        feed.entries << feed_item.to_atom(:base_uri => base_uri,
                                          :include_tags => filters[:user].tags + 
                                                           filters[:user].subscribed_tags)
      end
    end
  end  
  
  # Performs a find(:all) using the options generated by passing the filters argument to 
  # options_for_filters.
  #
  # When a user is provided in the filters hash this method will also do some prefetching of
  # the user and classifier taggings for the items loaded. This uses the caching mechanism
  # provided by the FindByTagger module.  The advantage of this is that you no longer need 
  # N + 1 queries to get the taggings for each item, instead there are just 3 queries, one 
  # to get the items and one each to get the taggings for the user and user's classifier.
  #
  # Note: The Rails eager loading mechanism can't substitute for this custom solution because
  # of the complexity of the joining in the query produced by options_with_filters.
  #
  def self.find_with_filters(filters = {})    
    user = filters[:user]
    
    options_for_find = send(SEARCH_OPTIONS, filters).merge(:select => [
      'feed_items.*', 'feeds.title AS feed_title', 
      "EXISTS (SELECT 1 FROM read_items WHERE read_items.feed_item_id = feed_items.id AND read_items.user_id = #{user.id}) AS read_by_current_user"
    ].join(","))
    options_for_find[:joins] ||= ""
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
      end.to_a.sort_by { |tag, _taggings| tag.name.downcase }
    end
    
    feed_items
  end
  
  # SELECT feed_items.*,feeds.title AS feed_title,EXISTS (SELECT 1 FROM read_items WHERE read_items.feed_item_id = feed_items.id AND read_items.user_id = 16) AS read_by_current_user FROM `feed_items` INNER JOIN feed_item_text_indices ON feed_items.id = feed_item_text_indices.feed_item_id AND MATCH(content) AGAINST('lotswholetime' IN BOOLEAN MODE) LEFT JOIN feeds ON feed_items.feed_id = feeds.id WHERE (feed_items.feed_id NOT IN (256,1024)) ORDER BY feed_items.updated DESC LIMIT 40
  # Completed in 0.11267 (8 reqs/sec) | Rendering: 0.01139 (10%) | DB: 0.02513 (22%) | 200 OK [http://localhost/feed_items?order=date&direction=desc&mode=all&text_filter=lotswholetime]

  # title|real_content|author: lotswholetime
  # Completed in 0.09527 (10 reqs/sec) | Rendering: 0.00981 (10%) | DB: 0.01750 (18%) | 200 OK [http://localhost/feed_items?order=date&direction=desc&mode=all&text_filter=lotswholetime]
  
  def self.mark_read(filters)
    options_for_find = send(SEARCH_OPTIONS, filters)   

    feed_item_ids_sql = "SELECT DISTINCT #{filters[:user].id}, feed_items.id, UTC_TIMESTAMP() FROM feed_items"
    feed_item_ids_sql << " #{options_for_find[:joins]}" unless options_for_find[:joins].blank?
    feed_item_ids_sql << " WHERE #{sanitize_sql(options_for_find[:conditions])}" unless options_for_find[:conditions].blank?

    ReadItem.connection.execute "INSERT IGNORE INTO read_items (user_id, feed_item_id, created_at) #{feed_item_ids_sql}"
  end
  
  def self.mark_read_for(user_id, feed_item_id)
    ReadItem.find_or_create_by_user_id_and_feed_item_id(user_id, feed_item_id)
  end
  
  # This builds the SQL to use for the find_with_filters and count_with_filters methods.
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
  # Also supports <tt>:limit</tt>, <tt>:offset</tt> and <tt>:order</tt> as defined by ActiveRecord::Base.find
  #
  # This will return a Hash of options suitable for passing to FeedItem.find.
  # 
  def self.options_for_filters_mysql(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :offset => filters[:offset]}
    
    direction = case filters[:direction]
      when "asc", "desc"
        filters[:direction].upcase
    end
    
    options[:order] = case filters[:order]
    when "strength"
      if filters[:tag_ids].blank?
        tag_ids = (filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags).map(&:id).join(',')
      else
        tag_ids = Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]]).map(&:id).join(",")
      end
      "(SELECT MAX(taggings.strength) FROM taggings WHERE taggings.tag_id IN (#{tag_ids}) AND taggings.feed_item_id = feed_items.id) #{direction}, feed_items.updated #{direction}"
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
    elsif filters[:mode] =~ /moderated/i # limit the search to tagged items
      filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags
    else
      tags = []
    end
    conditions << build_tag_inclusion_filter(tags, filters[:mode])

    conditions = ["(#{conditions.compact.join(" OR ")})"] unless conditions.compact.blank? 
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      conditions << build_tag_exclusion_filter(filters[:user].excluded_tags)
    end
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      add_globally_exclude_feed_filter_conditions!(filters[:user].excluded_feeds, conditions)
    end
    
    if filters[:mode] =~ /unread/i # only filter out read items when showing unread items
      add_read_items_filter_conditions!(filters[:user], conditions)
    end
        
    options[:conditions] = conditions.compact.blank? ? nil : conditions.compact.join(" AND ")
    options[:joins] = joins.uniq.join(" ")
    
    options
  end
  
  def self.options_for_filters_part_ferret(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :offset => filters[:offset]}
    
    direction = case filters[:direction]
      when "asc", "desc"
        filters[:direction].upcase
    end
    
    options[:order] = case filters[:order]
    when "strength"
      if filters[:tag_ids].blank?
        tag_ids = (filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags).map(&:id).join(',')
      else
        tag_ids = Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]]).map(&:id).join(",")
      end
      "(SELECT MAX(taggings.strength) FROM taggings WHERE taggings.tag_id IN (#{tag_ids}) AND taggings.feed_item_id = feed_items.id) #{direction}, feed_items.updated #{direction}"
    when "date"
      "feed_items.updated #{direction}"
    when "id"
      "feed_items.id #{direction}"
    else
      "feed_items.updated DESC"
    end

    filters[:mode] ||= "unread"

    conditions = []

    unless filters[:text_filter].blank?
      feed_item_ids = FeedItem.find_ids_with_ferret(filters[:text_filter], :limit => :all).last.map { |h| h[:id] }
      conditions << "feed_items.id IN (#{feed_item_ids.join(',')})" unless feed_item_ids.blank?
    end
    
    add_feed_filter_conditions!(filters[:feed_ids], conditions)
    
    tags = if filters[:tag_ids]
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]])
    elsif filters[:mode] =~ /moderated/i # limit the search to tagged items
      filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags
    else
      tags = []
    end
    conditions << build_tag_inclusion_filter(tags, filters[:mode])

    conditions = ["(#{conditions.compact.join(" OR ")})"] unless conditions.compact.blank? 
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      conditions << build_tag_exclusion_filter(filters[:user].excluded_tags)
    end
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      add_globally_exclude_feed_filter_conditions!(filters[:user].excluded_feeds, conditions)
    end
    
    if filters[:mode] =~ /unread/i # only filter out read items when showing unread items
      add_read_items_filter_conditions!(filters[:user], conditions)
    end
        
    options[:conditions] = conditions.compact.blank? ? nil : conditions.compact.join(" AND ")
    
    options
  end
  
  def self.options_for_filters_full_ferret(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :offset => filters[:offset]}
    
    direction = case filters[:direction]
      when "asc", "desc"
        filters[:direction].upcase
    end
    
    options[:order] = case filters[:order]
    when "strength"
      if filters[:tag_ids].blank?
        tag_ids = (filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags).map(&:id).join(',')
      else
        tag_ids = Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]]).map(&:id).join(",")
      end
      "(SELECT MAX(taggings.strength) FROM taggings WHERE taggings.tag_id IN (#{tag_ids}) AND taggings.feed_item_id = feed_items.id) #{direction}, feed_items.updated #{direction}"
    when "date"
      "feed_items.updated #{direction}"
    when "id"
      "feed_items.id #{direction}"
    else
      "feed_items.updated DESC"
    end

    filters[:mode] ||= "unread"

    query = []

    feeds = Feed.find_all_by_id(filters[:feed_ids].to_s.split(','))
    unless feeds.blank?
      query << "feed_id: (#{feeds.map(&:id).join(' OR ')})"
    end
    
    tags = if filters[:tag_ids]
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]])
    elsif filters[:mode] =~ /moderated/i # limit the search to tagged items
      filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags
    else
      tags = []
    end
    unless tags.blank?
      if filters[:mode] =~ /moderated/i
        query << "user_tag_ids_with_spaces: (#{tags.map(&:id).join(' OR ')})"
      else
        query << "tag_ids_with_spaces: (#{tags.map(&:id).join(' OR ')})"
      end
    end
    query = ["(#{query.join(' OR ')})"] unless query.blank?

    unless filters[:text_filter].blank?
      query << "title|real_content|author: #{filters[:text_filter]}"
    end
    
    excluded_tags = filters[:user].excluded_tags
    if filters[:mode] !~ /moderated/i && excluded_tags.any? # don't filter excluded items when showing moderated items
      query << "-tag_ids_with_spaces: (#{excluded_tags.map(&:id).join(' OR ')})"
    end
    
    excluded_feeds = filters[:user].excluded_feeds
    if filters[:mode] !~ /moderated/i && excluded_feeds.any? # don't filter excluded items when showing moderated items
      query << "-feed_id: (#{excluded_feeds.map(&:id).join(' OR ')})"
    end
    
    if filters[:mode] =~ /unread/i # only filter out read items when showing unread items
      query << "-reader_ids_with_spaces: #{filters[:user].id}"
    end

    # puts "FERRET QUERY: #{query.join(' ')}"

    feed_item_ids = if query.blank?
      options
    else
      feed_item_ids = FeedItem.find_ids_with_ferret(query.join(" "), :limit => :all).last.map { |h| h[:id] }
      if feed_item_ids.blank?
        options.merge(:conditions => "feed_items.id IS NULL")
      else
        options.merge(:conditions => ["feed_items.id IN (?)", feed_item_ids])
      end
    end
  end
  
  def self.options_for_filters_sphinx(filters)
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :offset => filters[:offset]}
    
    direction = case filters[:direction]
      when "asc", "desc"
        filters[:direction].upcase
    end
    
    options[:order] = case filters[:order]
    when "strength"
      if filters[:tag_ids].blank?
        tag_ids = (filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags).map(&:id).join(',')
      else
        tag_ids = Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]]).map(&:id).join(",")
      end
      "(SELECT MAX(taggings.strength) FROM taggings WHERE taggings.tag_id IN (#{tag_ids}) AND taggings.feed_item_id = feed_items.id) #{direction}, feed_items.updated #{direction}"
    when "date"
      "feed_items.updated #{direction}"
    when "id"
      "feed_items.id #{direction}"
    else
      "feed_items.updated DESC"
    end

    filters[:mode] ||= "unread"

    unless filters[:text_filter].blank?
      options[:joins] = "INNER JOIN feed_item_search ON feed_items.id = feed_item_search.id AND feed_item_search.query = '#{sanitize_sql(filters[:text_filter])};mode=extended;limit=9999999'"
    end

    conditions = []

    add_feed_filter_conditions!(filters[:feed_ids], conditions)
    
    tags = if filters[:tag_ids]
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]])
    elsif filters[:mode] =~ /moderated/i # limit the search to tagged items
      filters[:user].sidebar_tags + filters[:user].subscribed_tags - filters[:user].excluded_tags
    else
      tags = []
    end
    conditions << build_tag_inclusion_filter(tags, filters[:mode])

    conditions = ["(#{conditions.compact.join(" OR ")})"] unless conditions.compact.blank? 
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      conditions << build_tag_exclusion_filter(filters[:user].excluded_tags)
    end
    
    unless filters[:mode] =~ /moderated/i # don't filter excluded items when showing moderated items
      add_globally_exclude_feed_filter_conditions!(filters[:user].excluded_feeds, conditions)
    end
    
    if filters[:mode] =~ /unread/i # only filter out read items when showing unread items
      add_read_items_filter_conditions!(filters[:user], conditions)
    end
        
    options[:conditions] = conditions.compact.blank? ? nil : conditions.compact.join(" AND ")
    
    options
  end
  
  # Add any text_filter. This is done using a inner join on feed_item_contents with an
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
      manual_taggings_sql = mode =~ /moderated/i ? " AND classifier_tagging = 0" : nil
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
  
  def self.add_read_items_filter_conditions!(user, conditions)
    conditions << "NOT EXISTS (SELECT 1 FROM read_items WHERE user_id = #{user.id} AND feed_item_id = feed_items.id)"
  end
  
  # Gets a UID suitable for use within the classifier
  def uid 
    "Winnow::FeedItem::#{self.id}"
  end

  def self.parse_id_uri(entry)
    begin
      uri = URI.parse(entry.id)
    
      if uri.fragment.nil?
        # TODO: localization
        raise ActiveRecord::RecordNotSaved, "Atom::Entry id is missing fragment: '#{entry.id}'"
      end
    
      uri.fragment.to_i
    rescue ActiveRecord::RecordNotSaved => e
      raise e
    rescue
      # TODO: localization
      raise ActiveRecord::RecordNotSaved, "Atom::Entry has missing or invalid id: '#{entry.id}'" 
    end
  end
end
