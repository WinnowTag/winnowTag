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
