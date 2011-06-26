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

class AddedCountsToTokenTable < ActiveRecord::Migration
  class FeedItemTokensContainer < ActiveRecord::Base; end
  
  def self.up
    add_column :feed_item_tokens_containers, :distinct_token_count, :integer
    add_column :feed_item_tokens_containers, :total_token_count, :integer

    FeedItemTokensContainer.find(:all, :select => 'id', :conditions => 'tokenizer_version = 2').each_with_index do |fitc, index|
      tokens = FeedItemTokensContainer.find(fitc.id)
      tokens.distinct_token_count = tokens.tokens.size
      tokens.total_token_count = tokens.tokens.inject(0) do |sum, token|
        sum + token.last.to_i
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
