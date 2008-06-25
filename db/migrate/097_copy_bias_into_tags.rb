# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CopyBiasIntoTags < ActiveRecord::Migration
  class BayesClassifier < ActiveRecord::Base
    serialize :bias
  end
  
  def self.up
    Tag.transaction do
      BayesClassifier.find(:all).each do |c|
        next unless c.bias
        c.bias.each do |tag, bias|
          if tag = Tag.find_by_user_id_and_name(c.user_id, tag)
            tag.bias = bias
            tag.save!
          end
        end
      end
    end
  end

  def self.down
  end
end
