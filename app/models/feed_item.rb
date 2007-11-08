# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Need to manually require feed_item since the winnow_feed plugin  defines
# these classes the auto-require functionality of Rails doesn't try to load the Winnow 
# additions to these classes.
load_without_new_constant_marking File.join(RAILS_ROOT, 'vendor', 'plugins', 'winnow_feed', 'lib', 'feed_item.rb')

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
# The original XML data is stored in a FeedItemXmlData.
#
# See also FeedItemContent, FeedItemXmlData and FeedItemTokensContainer.
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
      :select => "feed_items.id, fitc.tokens_with_counts as tokens_with_counts",
      :joins => "inner join random_backgrounds as rnd on feed_items.id = rnd.feed_item_id " +
                "inner join feed_item_tokens_containers as fitc on fitc.feed_item_id = feed_items.id" + 
                " and fitc.tokenizer_version = #{FeedItemTokenizer::VERSION}",
      :limit => size)
  end
  
  # Gets a count of the number of items that meet conditions applied by the filters.
  #
  # See options_for_filters.
  def self.count_with_filters(filters = {})
    options = options_for_filters(filters)
    options[:select] = 'distinct feed_items.id'
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
    feed_items = FeedItem.find(:all, options_for_filters(filters).merge(:select => 'distinct feed_items.id, feed_items.time,' +
                                                                      ' feed_items.link, feed_items.sort_title,' +
                                                                      ' feed_items.feed_id, feed_items.created_on'))
    
    if user = filters[:view].user
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

    UnreadItem.delete_all(["user_id = ? AND feed_item_id IN (#{feed_item_ids_sql})", filters[:view].user])
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
  # A Hash with thiese keys (all optional):
  #
  # <tt>:view</tt>:: Constrains returned items to the parameters defined in the view
  # <tt>:only_tagger</tt>:: Can be 'user' or 'classifier'.  Constrains the type of tagger in a tag filter to user or classifier.
  # <tt>:include_negative</tt>:: (true|false) If true negative taggings will be included in a tag_filters results. Default is false.
  # 
  # Also supports <tt>:limit</tt>, <tt>:offset</tt> and <tt>:order</tt> as defined by ActiveRecord::Base.find
  #
  # This will return a Hash of options suitable for passing to FeedItem.find.
  # 
  def self.options_for_filters(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :offset, :view, :only_tagger, :include_negative)
    options = {:limit => filters[:limit], :order => filters[:order], :offset => filters[:offset]}
    view = filters[:view]

    joins = []
    conditions = []
    
    # Feed filtering (include/exclude)
    add_feed_filter_conditions!(view.feed_filters, conditions)
          
    # Tag filtring (include/exclude)
    tag_inclusion_filter_by_user = {}
    tag_exclusion_filter_by_user = {}
    
    view.tag_filters.include.each do |tag_filter|
      next unless tag = tag_filter.tag
      tag_inclusion_filter_by_user[tag.user] ||= []
      tag_inclusion_filter_by_user[tag.user] << tag.id
    end
    
    view.tag_filters.exclude.each do |tag_filter|
      next unless tag = tag_filter.tag
      tag_exclusion_filter_by_user[tag.user] ||= []
      tag_exclusion_filter_by_user[tag.user] << tag.id
    end

    include_conditions, exclude_conditions = [], []
    (tag_inclusion_filter_by_user.keys + tag_exclusion_filter_by_user.keys).uniq.each do |tagger|
      add_tag_filter_joins!(tagger, filters[:include_negative], filters[:only_tagger], joins)
      add_tag_exclusion_conditions!(tagger, tag_exclusion_filter_by_user[tagger], filters[:include_negative], filters[:only_tagger], exclude_conditions)
      add_tag_inclusion_conditions!(tagger, tag_inclusion_filter_by_user[tagger], include_conditions)
    end
    conditions << "(#{include_conditions.join(" OR ")})" unless include_conditions.blank?
    conditions << "(#{exclude_conditions.join(" AND ")})" unless exclude_conditions.blank?
    
    # Untagged filtering
    if !view.show_untagged?
      add_tag_filter_joins!(view.user, filters[:include_negative], filters[:only_tagger], joins)
      add_tagged_state_conditions!(view.user, conditions)
      
      view.user.subscribed_tags.each do |tag|
        add_tag_filter_joins!(tag.user, filters[:include_negative], filters[:only_tagger], joins)
      end
    elsif view.show_untagged? && !view.feed_filters.include.blank? && !view.feed_filters.exclude.blank?
      add_tag_filter_joins!(view.user, filters[:include_negative], filters[:only_tagger], joins)
      taggings_alias = taggings_alias_for(view.user)
      conditions << "#{taggings_alias}.id IS NULL"
    end
        
    options[:conditions] = conditions.empty? ? nil : conditions.join(" AND ")
    
    add_always_include_feed_filter_conditions!(view.feed_filters.always_include, options[:conditions])
    
    # The untagged filter is only added if we are doing any sort of tag filtering.
    # This ensures that there are no unneccesary joins to include untagged items
    # when we are not filtering on tags anyway.
    if view.show_untagged? && view.feed_filters.include.blank? && view.feed_filters.exclude.blank? &&
                            !(view.tag_filters.include.blank? && view.tag_filters.exclude.blank?)
      add_tag_filter_joins!(view.user, filters[:include_negative], filters[:only_tagger], joins)
      add_untagged_state_conditions!(view.user, options[:conditions])
    end
    
    # Text filtering
    add_text_filter_joins!(view.text_filter, joins)
    add_text_filter_conditions!(view.text_filter, options[:conditions] ||= "")
    
    options[:conditions] = nil if options[:conditions].blank?
    
    options[:joins] = joins.uniq.join(" ")
    
    options
  end
  
  # Returns an SQL join statement that restricts feed items to those that match a query string
  #
  # Currently uses the a MySQL full text index on the feed_item_contents_full_text table.
  #
  def self.text_filter_join(query)
    "JOIN feed_item_contents_full_text ON " +
        "feed_items.id = feed_item_contents_full_text.id AND " +
        "MATCH(content) AGAINST(#{connection.quote(query)} IN BOOLEAN MODE) "
  end
  
  def self.add_feed_filter_conditions!(feed_filters, conditions)
    if feed_filters
      if !feed_filters.include.empty?
        conditions << "feed_items.feed_id IN (#{feed_filters.include.map(&:feed_id).join(",")})"
      end
    
      if !feed_filters.exclude.empty?
        conditions << "feed_items.feed_id NOT IN (#{feed_filters.exclude.map(&:feed_id).join(",")})"
      end
    end
  end
  
  # Add any text_filter. This is done using a inner join on feed_item_contents with an
  # additional join condition that applies the text filter using the full text index.
  def self.add_text_filter_joins!(text_filter, joins)
    if text_filter
      joins << "LEFT JOIN feed_item_contents_full_text ON feed_items.id = feed_item_contents_full_text.id"
    end
  end
  
  def self.add_text_filter_conditions!(text_filter, conditions)
    if text_filter
      new_conditions = "MATCH(content) AGAINST(#{connection.quote(text_filter)} IN BOOLEAN MODE)"
      new_conditions << "AND (#{conditions})" unless conditions.blank?
      conditions.replace new_conditions
    end
  end

  # First we need to build up the tagger condition.
  # 
  # Start by creating a condition using the tagger types for User and the Classifier.  
  # If :include_negative is false the  strength column is also constrained to be only 
  # positive taggings.
  #
  # Then if :only_tagger is set to either user or classifier, the condition for the tagger
  # we don't need is set to false.
  #
  # Finally combine the user and classifier tagger conditions with a condition that constrains
  # all taggings to have the user_id equal to the id of the user. This is the tagger_condition.
  def self.tagger_condition_for(user, include_negative, only_tagger, taggings_alias = "taggings")
    conditions = ["#{taggings_alias}.user_id = #{user.id}"]
    
    
    if only_tagger == "user"
      conditions << "#{taggings_alias}.classifier_tagging = 0"
    elsif only_tagger == "classifier"
      conditions << "#{taggings_alias}.classifier_tagging = 1"
    end
    
    unless include_negative
      # This is the borderline cutoff
      conditions << ("#{taggings_alias}.strength >= 0.88 AND 0 = ( " <<
                      "SELECT COUNT(*) FROM taggings WHERE " <<
                      "taggings.feed_item_id = #{taggings_alias}.feed_item_id AND " <<
                      "taggings.tag_id = #{taggings_alias}.tag_id AND " <<
                      "taggings.classifier_tagging = 0 AND "<<
                      "taggings.strength = 0" <<
                    ")")
    end
    
    "(#{conditions.join(" AND ")})"
  end
  
  def self.taggings_alias_for(tagger)
    "#{tagger.class.name.downcase}_#{tagger.id}_taggings"
  end
  
  def self.add_tag_filter_joins!(tagger, include_negative, only_tagger, joins)
    taggings_alias = taggings_alias_for(tagger)
    tagger_condition = tagger_condition_for(tagger, include_negative, only_tagger, taggings_alias)

    
    joins << "LEFT OUTER JOIN taggings #{taggings_alias} ON " <<
             "#{taggings_alias}.feed_item_id = feed_items.id AND " <<
             tagger_condition
  end
  
  def self.add_tag_exclusion_conditions!(tagger, tag_filter, include_negative, only_tagger, conditions)
    unless tag_filter.blank?
      taggings_alias = taggings_alias_for(tagger) + "_excluded"
      tagger_condition = tagger_condition_for(tagger, include_negative, only_tagger, taggings_alias)
      
      conditions << <<-EOSQL
        feed_items.id NOT IN(
          SELECT feed_item_id FROM taggings #{taggings_alias}
          WHERE #{tagger_condition} AND #{taggings_alias}.tag_id IN (#{tag_filter.join(",")})
        )
      EOSQL
    end
  end
  
  def self.add_tag_inclusion_conditions!(user, tag_filter, conditions)
    unless tag_filter.blank?
      taggings_alias = taggings_alias_for(user)
      tag_conditions = ["#{taggings_alias}.id IS NOT NULL AND #{taggings_alias}.tag_id IN (#{tag_filter.join(",")})"]
      conditions.concat(tag_conditions)
    end
  end
  
  def self.add_tagged_state_conditions!(user, conditions)
    taggings_alias = taggings_alias_for(user)
    ored_conditions = ["#{taggings_alias}.id IS NOT NULL"]
    
    user.subscribed_tags.group_by(&:user).each do |user, tags|
      taggings_alias = taggings_alias_for(user)
      ored_conditions << "#{taggings_alias}.tag_id IN (#{tags.map(&:id).join(",")})"
    end
    
    conditions << "(#{ored_conditions.join(" OR ")})"
  end
  
  def self.add_untagged_state_conditions!(tagger, conditions)
    if !conditions.blank?
      taggings_alias = taggings_alias_for(tagger)
      conditions.replace "#{taggings_alias}.id IS NULL OR (#{conditions})"
    end
  end
  
  def self.add_always_include_feed_filter_conditions!(feed_filters, conditions)
    if !conditions.blank? and !feed_filters.blank?
      conditions.replace "feed_items.feed_id IN (#{feed_filters.map(&:feed_id).join(",")}) OR (#{conditions})"
    end
  end
  
  # Gets the tokens with frequency counts for the feed_item.
  # 
  # This return a hash with token => freqency entries.
  #
  # There are a number of different ways to get the tokens for an item:
  # 
  # The fastest, providing the token already exists, is to select out the 
  # tokens field from the feed_item_tokens_containers table as a field of
  # the feed item. In this case the tokens will be unmarshaled without type
  # casting.
  #
  # You can also include the :latest_tokens association on a query for feed
  # items which will get the tokens with the highest tokenizer version.  This
  # method will require Rails to build the association so it is slower than the 
  # previously described method.
  #
  # Finally, the slowest, but also the method that will create the tokens if the
  # dont exists is to pass version and a block, if there are no tokens matching the 
  # tokenizer version the block is called and a token container will be created
  # using the result from the block as the tokens. This is the method used by
  # FeedItemTokenizer#tokens.
  #
  def tokens_with_counts(version = FeedItemTokenizer::VERSION, force = false)
    if block_given? and force
      tokens = yield(self)
      token_containers.create(:tokens_with_counts => tokens, :tokenizer_version => version)
      tokens
    elsif tokens = read_attribute_before_type_cast('tokens_with_counts')
      Marshal.load(tokens)  
    elsif self.latest_tokens and self.latest_tokens.tokenizer_version == version
      self.latest_tokens.tokens_with_counts
    elsif token_container = self.token_containers.find(:first, :conditions => ['tokenizer_version = ?', version])
      token_container.tokens_with_counts
    elsif block_given?
      tokens = yield(self)
      token_containers.create(:tokens_with_counts => tokens, :tokenizer_version => version)
      tokens
    end
  end
  
  # Gets the tokens without frequency counts.
  #
  # This method requires the tokens to have already been extracted and stored in the token_container.
  # 
  def tokens(version = FeedItemTokenizer::VERSION)
    if tokens = read_attribute_before_type_cast('tokens')
      Marshal.load(tokens)
    elsif self.latest_tokens and self.latest_tokens.tokenizer_version == version
      self.latest_tokens.tokens
    elsif token_container = self.token_containers.find(:first, :conditions => ['tokenizer_version = ?', version])
      token_container.tokens
    end
  end
  
  # Gets a UID suitable for use within the classifier
  def uid 
    "Winnow::FeedItem::#{self.id}"
  end
  
  # Gets the content of this feed.
  # This method will handle generating the feed item content from the xml data
  # if it doesnt already exist on the feed_item_content association.
  def content(force = false)
    unless self.feed_item_content
      self.build_feed_item_content
    end
    self.feed_item_content(force)
  end

  # Get the display title for this feed item.
  def display_title
    if self.content.title and not self.content.title.empty?
      self.content.title
    elsif self.content.encoded_content and self.content.encoded_content.match(/^<?p?>?<(strong|h1|h2|h3|h4|b)>([^<]*)<\/\1>/i)
      $2
    elsif self.content.encoded_content.is_a? String
      self.content.encoded_content.split(/\n|<br ?\/?>/).each do |line|
        potential_title = line.gsub(/<\/?[^>]*>/, "").chomp # strip html
        break potential_title if potential_title and not potential_title.empty?
      end.split(/!|\?|\./).first
    else
      ""
    end
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
      tagging_hash =  taggings.select{|t| t.classifier_tagging?}.inject({}) do |hash, tagging|
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
end
