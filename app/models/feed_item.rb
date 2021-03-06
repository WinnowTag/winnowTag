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


# Provides a representation of an item from an RSS/Atom feed.
#
# This class includes methods for:
#
# * Finding items based on taggings and other filters.
#
# The +FeedItem+ class only stores summary metadata for a feed item, the actual
# content is stored in the +FeedItemContent+ class. This enables faster database
# access on the smaller summary records and allows us to use a MyISAM table for
# the content which can then be index using MySQL's Full Text Indexing.
#
# See also +FeedItemContent+
class FeedItem < ActiveRecord::Base
  acts_as_readable
  
  attr_readonly :uri
  # Taggings to display is used in the +find_with_filters+ method
  attr_accessor :taggings_to_display

  validates_presence_of :link
  belongs_to :feed, :counter_cache => true
  has_one :content, :dependent => :delete, :class_name => 'FeedItemContent'
  has_one :text_index, :dependent => :delete, :class_name => 'FeedItemTextIndex'
  has_many :taggings
  has_many :classifier_taggings, :dependent => :delete_all, :conditions => ["classifier_tagging = ?", true], :class_name => "Tagging"
  has_many :manual_taggings, :conditions => ["classifier_tagging = ?", false], :class_name => "Tagging"
  has_many :tags, :through => :taggings
  after_create :touch_feed
  
  # Takes an atom entry and either finds the FeedItem with the matching id and updates
  # it or creates a new feed item with the content from the atom entry.
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
  
  # Updates self with the content of the atom entry.
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
  
  # Converts a +FeedItem+ into an atom entry.
  #
  # Supported options are:
  # 
  #  - include_tags: If true the tags the item is assigned to are output as categories on the entry.
  #  - training_only: If this and +include_tags+ is true only manually created tags are output.
  #  - base_uri: The base uri to use for all urls it produces.
  #
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
  
  def touch_feed
    self.feed.touch if self.feed
  end
  
  def before_destroy
    self.manual_taggings.empty?
  end
  
  # Destroy feed items older than +since+.
  #
  # This also deletes all classifier taggings that are on items older than +since+,
  # Manual taggings are untouched.
  #
  # You could do this in the one SQL statement, however using ActiveRecord,
  # while taking slightly longer, will break this up into multiple transactions
  # and reduce the chance of getting a deadlock with a long transaction.
  def self.archive_items(since = 30.days.ago.getutc, feed_min = 200, stdout_log = false)
    taggings_deleted = Tagging.delete_all(['classifier_tagging = ? and feed_item_id IN (select id from feed_items where updated < ?)', true, since])
    conditions = ['updated < ? and ' +
                  'NOT EXISTS (select feed_item_id from taggings where feed_item_id = feed_items.id) and ' +
                  '(select count(*) from feed_items fi where fi.feed_id = feed_items.feed_id group by feed_id) > ?', 
                  since, feed_min]
    counter = 0
    FeedItem.find_each(:conditions => conditions) do |item|
      item.destroy
      counter += 1
    end
    logger.info("ARCHIVAL: Deleted #{counter} items and #{taggings_deleted} classifier taggings older than #{since}")
    puts("ARCHIVAL: Deleted #{counter} items and #{taggings_deleted} classifier taggings older than #{since}") if stdout_log
  end
  
  # The +atom_with_filters+ method is used to find all feed items matching the 
  # filters set by the user, and return them an ATOM feed of those results.
  def self.atom_with_filters(filters = {})
    base_uri = filters.delete(:base_uri)
    self_link = filters.delete(:self_link)
    alt_link = filters.delete(:alt_link)
    items = self.find_with_filters(filters)

    tags = filters[:tag_ids].to_s.split(",").map {|id| Tag.find(id) }.map { |t| "'#{t.name}'" }
    feeds = filters[:feed_ids].to_s.split(",").map {|id| Feed.find(id) }.map { |f| "'#{f.title}'" }
    text_filter = filters[:text_filter]
    mode = filters[:mode]

    # The title of the ATOM feed is based on the filter criteria. This whole black
    # is used to determine what that title will be based on what filters are present.
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
  # the user and classifier taggings for the items loaded. The advantage of this is that you no longer need 
  # N + 1 queries to get the taggings for each item, instead there are just 3 queries, one 
  # to get the items and one each to get the taggings for the user and user's classifier.
  #
  # Note: The Rails eager loading mechanism can't substitute for this custom solution because
  # of the complexity of the joining in the query produced by +options_with_filters+.
  def self.find_with_filters(filters = {})    
    user = filters[:user]
    
    options_for_find = options_for_filters(filters).merge(:select => [
      'feed_items.*', 'feeds.title AS feed_title', 
      "(select strength from taggings where taggings.feed_item_id = feed_items.id AND taggings.tag_id IN (#{filters[:tag_ids] or 0}) and taggings.classifier_tagging = 0) as tagged_type",
      "EXISTS (SELECT 1 FROM readings WHERE readings.readable_type = 'FeedItem' AND readings.readable_id = feed_items.id AND readings.user_id = #{user.id}) AS read_by_current_user"
    ].join(","))
    options_for_find[:joins] << " LEFT JOIN feeds ON feed_items.feed_id = feeds.id"
    
    FeedItem.find(:all, options_for_find)
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
  def self.options_for_filters(filters) # :doc:
    filters.assert_valid_keys(:limit, :order, :direction, :offset, :mode, :user, :feed_ids, :tag_ids, :text_filter)
    options = { :limit => filters[:limit], :offset => filters[:offset] }
    
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

    joins = []
    add_text_filter_joins!(filters[:text_filter], joins)

    conditions = []
    add_feed_filter_conditions!(filters[:feed_ids], conditions)
    
    tags = if filters[:tag_ids]
#      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", filters[:tag_ids].to_s.split(","), true, filters[:user]])
      Tag.find(:all, :conditions => ["tags.id IN(?)", filters[:tag_ids].to_s.split(",")])
    elsif filters[:mode] =~ /trained/i # limit the search to tagged items
      filters[:user].subscribed_tags - filters[:user].excluded_tags
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
  
  # Add any +text_filter+. This is done using a inner join on +feed_item_text_indices+ with an
  # additional join condition that applies the text filter using the full text index.
  def self.add_text_filter_joins!(text_filter, joins)
    unless text_filter.blank?
      joins << "INNER JOIN feed_item_text_indices ON feed_items.id = feed_item_text_indices.feed_item_id" +
               " AND MATCH(content) AGAINST(#{connection.quote(parse_text_filter(text_filter))} IN BOOLEAN MODE)"
    end
  end
  
  # Adds the conditions for the selected feeds
  def self.add_feed_filter_conditions!(feed_ids, conditions)
    feeds = Feed.find_all_by_id(feed_ids.to_s.split(','))
    unless feeds.empty?
      conditions << "feed_items.feed_id IN (#{feeds.map(&:id).join(",")})"
    end
  end

  # Adds the conditions for the selected tags
  def self.build_tag_inclusion_filter(tags, mode)
    unless tags.empty?
      manual_taggings_sql = mode =~ /trained/i ? " AND classifier_tagging = 0" : nil
      "EXISTS (SELECT 1 FROM taggings WHERE tag_id IN(#{tags.map(&:id).join(",")}) AND feed_item_id = feed_items.id#{manual_taggings_sql})"
    end
  end

  # Adds the conditions for the excluded tags
  def self.build_tag_exclusion_filter(tags)
    unless tags.empty?
      "NOT EXISTS (SELECT 1 FROM taggings WHERE tag_id IN(#{tags.map(&:id).join(",")}) AND feed_item_id = feed_items.id)"
    end
  end
  
  # Adds the conditions for the excluded feeds
  def self.add_globally_exclude_feed_filter_conditions!(feeds, conditions)
    unless feeds.empty?
      conditions << "feed_items.feed_id NOT IN (#{feeds.map(&:id).join(",")})"
    end
  end
  
  # Adds the conditions dispay only unred items
  def self.add_readings_filter_conditions!(user, conditions)
    conditions << "NOT EXISTS (SELECT 1 FROM readings WHERE readings.user_id = #{user.id} AND readings.readable_type = 'FeedItem' AND readings.readable_id = feed_items.id)"
  end
  
  # Convert simple Google-like syntax:
  #
  #   phrases quoted with single or double quotes
  #   implied AND
  #   explicit OR (as in Google, operator can be "OR" or "|")
  #   "-" negation
  #
  # ...to MySQL binary mode full text search syntax.
  #

  OR_OP = 'OR'

  def self.parse_text_filter (text)
    def self.remove_extra_ors(t)
      prev = OR_OP
      u = []
      t.each_index { |i|
        u << prev = t[i] unless t[i] == OR_OP && prev == OR_OP
      }
      u.pop if u.last == OR_OP
      return u
    end

    # Remove parens & scan reserving both double and single quoted phrases.
    # Preserve leading "-" in both keywords and quoted phrases but drop
    # leading "+".
    t = text.gsub(/[()]/, ' ').scan(/-*?'.*?'|-*?".*?"|\S+/) #.reject { |token| token =~ /^\s+$/ }

    # Handle OR of any case and also | (as Google)
    t.map! { |e| (e.upcase == OR_OP || e == '|') ? OR_OP : e }

    # Discard multiple sequential OR operators, and trailing or leading OR
    # operators (which do not have both operands). This may not be strictly
    # necessary but it's nice to avoid thinking about meaningless edge cases,
    # at the least.
    t = remove_extra_ors(t)

    o = []
    i = 0
    prev = OR_OP
    while i < t.size do
      prev = t[i]
      i += 1
      if t[i] == OR_OP
        o << "+(" << prev
        while i < t.size && t[i] == OR_OP && (i + 1) < t.size do
          i += 1
          o << t[i]
          i += 1
        end
        o << ")"
      else
        if prev.match(/^-/)
          o << prev
        else
          o << "+" + prev
        end
      end
    end
    return o.join(' ')
  end
end
