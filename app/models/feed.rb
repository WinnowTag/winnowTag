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
  alias_attribute :name, :title

  def self.search options = {}
    joins = []
    conditions, values = ['is_duplicate = ?'], [false]
    
    if options[:subscribed_by]
      joins << "INNER JOIN feed_subscriptions ON feeds.id = feed_subscriptions.feed_id AND feed_subscriptions.user_id = #{options[:subscribed_by].id}"
    end
    
    unless options[:search_term].blank?
      conditions << '(title LIKE ? OR url LIKE ?)'
      values << "%#{options[:search_term]}%" << "%#{options[:search_term]}%"
    end
  
    select = ["feeds.*"]
    if options[:excluder]
      select << "((SELECT COUNT(*) FROM feed_exclusions WHERE feeds.id = feed_exclusions.feed_id AND feed_exclusions.user_id = #{options[:excluder].id}) > 0) AS globally_exclude"
    end
    
    paginate(:select => select.join(","),
             :joins => joins.join(" "),
             :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values],
             :page => options[:page],
             :group => "feeds.id",
             :order => options[:order])
  end
  
  def self.find_by_url_or_link(url)
    self.find(:first, :conditions => ['url = ? or link = ?', url, url])
  end
end
