# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddedCountsToTokenTable < ActiveRecord::Migration
  class FeedItemTokensContainer < ActiveRecord::Base; end
  
  def self.up
    add_column :feed_item_tokens_containers, :distinct_token_count, :integer
    add_column :feed_item_tokens_containers, :total_token_count, :integer

    FeedItemTokensContainer.find(:all, :select => 'id', :conditions => 'tokenizer_version = 2').each_with_index do |fitc, index|
      tokens = FeedItemTokensContainer.find(fitc.id)
      tokens.distinct_token_count = tokens.tokens.size
      tokens.total_token_count = tokens.tokens.inject(0) do |sum, token|
        sum + token.last
      end
      tokens.save!
      
      if index % 1000 == 0
        say "#{index} items processed."
      end
    end
  end

  def self.down
    remove_column :feed_item_tokens_containers, :distinct_token_count
    remove_column :feed_item_tokens_containers, :total_token_count
  end
end
