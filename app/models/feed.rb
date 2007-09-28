# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Need to manually require feed, bypassing new constant marking, since the winnow_feed plugin
# defines Feed the auto-require functionality of Rails doesn't try to load the Winnow 
# additions to these classes.  Putting it here makes sure it works in all modes.
load_without_new_constant_marking File.join(RAILS_ROOT, 'vendor', 'plugins', 'winnow_feed', 'lib', 'feed.rb')

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
  # Returns a list of feeds with the number of items in each feed.
  # An additional attribute 'item_count' will be provided that has a count of all feed items for
  # each feed which are tagged by the tagger with that tag.  If tagger and tag are not passed in
  # all feeds with items will be returned and item count will be the total count of the items.
  #
  # If the feed item count for a given fieed is 0 zero it is not returned.
  # === Parameters
  #
  # <tt>:tag_filter</tt>:: Limits the count of items to those that are tagged with the tag_filter. Must be provided with :user.
  # <tt>:user</tt>:: The user of the taggings to use with the tag_filter.
  # <tt>text_filter</tt>:: A substring to limit the items to count.
  #
  def self.find_with_item_counts(options = {})
    options.assert_valid_keys(:tag_filter, :user, :text_filter)
    
    if options[:text_filter]
      text_filter_joins = FeedItem.text_filter_join(options[:text_filter])
    end
    
    if options[:tag_filter] and !options[:tag_filter][:include].blank? and options[:user]
      if options[:tag_filter][:include].map(&:name).include?(Tag::TAGGED)
      
      else
        tag_filter_joins = "INNER JOIN taggings ON feed_items.id = taggings.taggable_id " <<
                           "AND taggings.taggable_type = 'FeedItem' " <<
                           "AND (#{options[:user].tagging_sql} OR #{options[:user].classifier.tagging_sql}) " <<
                           "AND taggings.deleted_at IS NULL " <<
                           "AND taggings.tag_id IN (#{options[:tag_filter][:include].map(&:id).join(",")})"
      end
      # if options[:tag_filter].tagged_filter?
      #   tag_filter_joins += " and taggings.tag_id = #{options[:tag_filter].id} "
      # end
    end
    
    self.find(:all, 
               :select => "feeds.*, count(distinct feed_items.id) as item_count",
               :joins => "inner join feed_items on feed_items.feed_id = feeds.id #{tag_filter_joins} #{text_filter_joins}",
               :conditions => ("active = 1 and feeds.title is not null"), 
               :group => 'feeds.id',
               :order => 'feeds.sort_title')
  end
end
