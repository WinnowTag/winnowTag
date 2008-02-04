# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

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
#
# See also FeedItemContent and FeedItemTokensContainer.
# 
# == Schema Information
# Schema version: 57
#
# Table name: feed_items
#
#  id             :integer(11)   not null, primary key
#  feed_id        :integer(11)   
#  sort_title     :string(255)   
#  time           :datetime      
#  created_on     :datetime      
#  unique_id      :string(255)   default("")
#  time_source    :string(255)   default("unknown")
#  xml_data_size  :integer(11)   
#  link           :string(255)   
#  content_length :integer(11)   
#  position       :integer(11)   
#

class FeedItem < ActiveRecord::Base
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
  has_many :taggings, :dependent => :delete_all do 
    def cached_taggings
      if @cached_taggings.nil?
        @cached_taggings = Hash.new([])
      end

      @cached_taggings
    end

    def find_by_user_with_caching(user, tag = nil)
      taggings = cached_taggings[user].select do |tagging|
        (tag.nil? or tagging.tag == tag)
      end

      cached_taggings.has_key?(user) ? taggings : find_by_user_without_caching(user, tag)
    end

    # Finds all taggings on this item by the given user.  You can also constrain
    # it to just taggings by a given tagger with a given tag by passing the tag in as
    # the second variable.
    #
    # This is an extension on the taggings association so use it like so:
    #
    #   taggable.taggings.find_by_user(user, tag)
    #
    def find_by_user(user, tag = nil)
      conditions = 'taggings.user_id = ? '
      conditions += ' and taggings.tag_id = ?' if tag
      conditions = [conditions, user.id]
      conditions += [tag.id] if tag

      find(:all, :conditions => conditions, :include => :tag, :order => 'tags.name ASC')
    end

    alias_method_chain :find_by_user, :caching
  end
  
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
      :joins => "inner join random_backgrounds as rnd on feed_items.id = rnd.feed_item_id ",
      :limit => size)
  end
  
  def self.find_or_create_from_atom(entry)
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
    raise ArgumentError, "Atom entry has different id" if self.id != self.class.parse_id_uri(entry)
    
    self.attributes = {
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
  
  # Gets a count of the number of items that meet conditions applied by the filters.
  #
  # See options_for_filters.
  def self.count_with_filters(filters = {})
    options = options_for_filters(filters)
    options[:select] = 'feed_items.id'
    options.delete(:limit)
    options.delete(:offset)
    FeedItem.count(options)
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
    feed_items = FeedItem.find(:all, options_for_filters(filters).merge(
                                                  :select => 'feed_items.id, feed_items.updated, feed_items.title, feed_items.link, ' +
                                                             'feed_items.feed_id, feed_items.created_on, feeds.title AS feed_title'))
    
    if user = filters[:user]
      feed_item_ids = feed_items.map(&:id)
      user_taggings = user.taggings.find(:all, :conditions => ['taggings.feed_item_id in (?)', feed_item_ids], :include => :tag)
            
      feed_items.each do |feed_item|
        user_taggings_for_item = user_taggings.select do |tagging|          
          tagging.feed_item_id == feed_item.id
        end
        
        feed_item.taggings.cached_taggings.merge!(user => user_taggings_for_item)
      end
    end
    
    feed_items
  end
  
  def self.mark_read(filters)
    options_for_find = options_for_filters(filters)   

    feed_item_ids_sql = "SELECT DISTINCT feed_items.id FROM feed_items"
    feed_item_ids_sql << " #{options_for_find[:joins]}" unless options_for_find[:joins].blank?
    feed_item_ids_sql << " WHERE #{options_for_find[:conditions]}" unless options_for_find[:conditions].blank?

    UnreadItem.delete_all(["user_id = ? AND feed_item_id IN (#{feed_item_ids_sql})", filters[:user]])
  end
  
  def self.mark_read_for(user_id, feed_item_id)
    UnreadItem.delete_all(["user_id = ? AND feed_item_id = ?", user_id, feed_item_id])
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
  # <tt>:view</tt>:: Constrains returned items to the parameters defined in the view
  # <tt>:manual_taggings</tt>:: (true|false) If true negative taggings will be included in a tag_filters results. Default is false.
  # 
  # Also supports <tt>:limit</tt>, <tt>:offset</tt> and <tt>:order</tt> as defined by ActiveRecord::Base.find
  #
  # This will return a Hash of options suitable for passing to FeedItem.find.
  # 
  def self.options_for_filters(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :offset, :manual_taggings, :user, :feed_ids, :tag_ids, :text_filter)
    options = {:limit => filters[:limit], :order => filters[:order], :offset => filters[:offset]}

    joins = ["LEFT JOIN feeds ON feed_items.feed_id = feeds.id"]
    conditions = []
    
    # Feed filtering (include)
    add_feed_filter_conditions!(filters[:feed_ids], conditions)
    
    tags = Tag.find_all_by_id(filters[:tag_ids].to_s.split(','))
    conditions += tags.map do |tag|
      build_tag_inclusion_filter(tag, filters[:manual_taggings])
    end
    conditions = [conditions.join(" OR ")] unless conditions.blank?
    
    conditions += filters[:user].excluded_tags.map do |tag|
      build_tag_exclusion_filter(tag)
    end
        
    options[:conditions] = conditions.join(" AND ")
    add_globally_exclude_feed_filter_conditions!(filters[:user].excluded_feeds, options[:conditions])

    # Text filtering
    add_text_filter_joins!(filters[:text_filter], joins)
    
    options[:conditions] = nil if options[:conditions].blank?    
    options[:joins] = joins.uniq.join(" ")
    
    options
  end
  
  def self.add_feed_filter_conditions!(feed_ids, conditions)
    feeds = Feed.find_all_by_id(feed_ids.to_s.split(','))
    if !feeds.empty?
      conditions << "feed_items.feed_id IN (#{feeds.map(&:id).join(",")})"
    end
  end
  
  # Add any text_filter. This is done using a inner join on feed_item_contents with an
  # additional join condition that applies the text filter using the full text index.
  def self.add_text_filter_joins!(text_filter, joins)
    if !text_filter.blank?
      joins << "INNER JOIN feed_item_text_indices ON feed_items.id = feed_item_text_indices.feed_item_id" +
               " and MATCH(content) AGAINST(#{connection.quote(text_filter)} IN BOOLEAN MODE)"
    end
  end

  def self.build_tag_inclusion_filter(tag, manual_taggings)
    negative_condition = ""
    if manual_taggings
      negative_condition = "AND classifier_tagging = 0"
    else
      negative_condition = "AND strength >= 0.88 "                +
                           "AND NOT EXISTS ("                     +
                              "SELECT 1 FROM taggings WHERE "     +
                              "tag_id = #{tag.id} AND "           +
                              "feed_item_id = feed_items.id AND " +
                              "classifier_tagging = 0 AND "       +
                              "strength = 0"                      +
                            ")"                                   
    end
    
    "EXISTS ("                                +
        "SELECT 1 FROM taggings WHERE "       +
        "tag_id = #{tag.id} AND "             +
        "feed_item_id = feed_items.id "       +
        negative_condition                    +
      ")"
  end

  def self.build_tag_exclusion_filter(tag)
    "NOT EXISTS ("                          +
      "SELECT 1 FROM taggings WHERE "       +
        "tag_id = #{tag.id} AND "           +
        "feed_item_id = feed_items.id AND " +
        "strength >= 0.88"                  +
    ")"
  end
  
  def self.add_always_include_feed_filter_conditions!(feed_filters, conditions)
    if !conditions.blank? and !feed_filters.blank?
      conditions.replace "feed_items.feed_id IN (#{feed_filters.map(&:feed_id).join(",")}) OR (#{conditions})"
    end
  end
  
  def self.add_globally_exclude_feed_filter_conditions!(feed_filters, conditions)
    return if feed_filters.blank?

    exclude_conditions = "feed_items.feed_id NOT IN (#{feed_filters.map(&:id).join(",")})"

    if conditions.blank?
      conditions.replace exclude_conditions
    else
      conditions.replace "#{exclude_conditions} AND (#{conditions})"
    end
  end
  
  # Gets a UID suitable for use within the classifier
  def uid 
    "Winnow::FeedItem::#{self.id}"
  end
  
  # Gets taggings between a list of taggers and this taggable.
  #
  # The priority functionality of this method is used to enforce the user taggings overriding classifier
  # taggings in the display.
  #
  # === Parameters
  #
  # <tt>:all_taggings</tt> <em>(true|false)</em>:: 
  #    If true return all taggings, not just the positive or priority ones. The default is false.
  #
  # === Return Structure
  #
  # The <tt>all_taggings</tt> option defines the struture of the returned object.
  #
  # The structure when true will be a 2D array where each element is an array with the first 
  # element being the tag and the second element being an array of taggings using that tag, 
  # in order of the taggers array.
  #
  # If false the structure will be a 2D array where the first element of each sub-array is the tag and the 
  # second element is the the first tagging for the tag as it appears in the order of the taggers array, i.e.
  # if the first tagger has a 'foo' tag and the second tagger also has a 'foo' tag, only the tagging from the
  # first tagger will be returned.
  #
  def taggings_by_user(user, options = {})
    options.assert_valid_keys([:all_taggings, :tags])  
    if options[:tags]
      taggings = self.taggings.find_all_by_user_id_and_tag_id(user, options[:tags])
    else
      taggings = self.taggings.find_by_user(user)
    end

    if options[:all_taggings]
      taggings.inject({}) do |hash, tagging|
        hash[tagging.tag] ||= []
        if tagging.classifier_tagging?
          hash[tagging.tag] << tagging
        else
          hash[tagging.tag].unshift(tagging)
        end
        hash
      end
    else
      # First put all the classifier ones down
      tagging_hash = taggings.select{|t| t.classifier_tagging?}.inject({}) do |hash, tagging|
        if tagging.positive? || tagging.borderline?
          hash[tagging.tag] = tagging
        end
        hash
      end
      
      # Now do user taggings, that override them
      taggings.select{|t| !t.classifier_tagging?}.inject(tagging_hash) do |hash, tagging|        
        if tagging.positive?
          hash[tagging.tag] = tagging
        elsif
          hash.delete(tagging.tag)
        end
        hash
      end
    end.to_a.sort
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
