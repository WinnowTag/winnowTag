# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddTokenArrayToTokenContainer < ActiveRecord::Migration
  class FeedItemTokensContainer < ActiveRecord::Base; end

  def self.up
    rename_column :feed_item_tokens_containers, :tokens, :tokens_with_counts
    add_column :feed_item_tokens_containers, :tokens, :text
    
    say "Extracting token arrays from token count Hashes"
    # For each token container, update the tokens attribute
    items = FeedItemTokensContainer.find(:all, :order => 'id', :limit => 2000)
    while items.any?
      items.each do |fitc|
        fitc.tokens = fitc.tokens_with_counts.keys
        fitc.save
      end
      
      items = FeedItemTokensContainer.find(:all, :order => 'id', :limit => 2000, 
                                    :conditions => ['id > ?', items.last.id])
    end
  end

  def self.down
    remove_column :feed_item_tokens_containers, :tokens
    rename_column :feed_item_tokens_containers, :tokens_with_counts, :tokens
  end
end
