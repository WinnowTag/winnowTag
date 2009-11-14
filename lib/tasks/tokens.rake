# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
namespace :winnow do
  desc "Tokenizes all feed items"
  task :tokenize => :environment do 
    rm_f File.join(RAILS_ROOT, "log/tokens.log")
    start = Time.now
    
    tokenizer = FeedItemTokenizer.new
    FeedItemTokensContainer.transaction do
      FeedItemTokensContainer.delete_all
      processed = 0
      items = FeedItem.find(:all, :conditions => ["feed_items.id > ?", 0], :include => :feed_item_content, :limit => 2000)
      while items.any?        
        items.each do |item| 
          tokenizer.tokens_with_counts(item, true)
        end
        
        puts "Processed #{processed += items.size} items..."
          
        items = FeedItem.find(:all, :conditions => ["feed_items.id > ?", items.last.id], :include => :feed_item_content, :limit => 2000)
      end
    end

    end_time = Time.now
    
    puts "Finished! Took #{(end_time - start) / 60} minutes."
  end
end
