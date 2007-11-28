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
  def self.search options = {}
    conditions, values = [], []
    
    unless options[:search_term].blank?
      conditions << '(title LIKE ? OR url LIKE ?)'
      values << "%#{options[:search_term]}%" << "%#{options[:search_term]}%"
    end
  
    select = ["feeds.*", "CASE view_feed_states.state WHEN 'exclude' THEN 0 WHEN 'always_include' THEN 1 ELSE 2 END AS view_state"]
    select << "((SELECT COUNT(*) FROM excluded_feeds WHERE feeds.id = excluded_feeds.feed_id AND excluded_feeds.user_id = #{options[:view].user_id}) > 0) AS globally_exclude"
    
    paginate(:select => select.join(","),
             :joins => "LEFT JOIN view_feed_states ON view_feed_states.feed_id = feeds.id " <<
                       "LEFT JOIN views ON views.id = view_feed_states.view_id AND views.id = #{options[:view].id}",
             :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values],
             :page => options[:page],
             :group => "feeds.id",
             :order => options[:order])
  end
  
  def globally_excluded?(user)
    user.excluded_feeds.find_by_feed_id(id)
  end
end
