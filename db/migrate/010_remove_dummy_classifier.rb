# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveDummyClassifier < ActiveRecord::Migration
  class Classifier < ActiveRecord::Base; end
  class DummyClassifier < Classifier
    has_many :taggings, :as => :tagger, :dependent => :delete_all
  end
  
  def self.up
    puts "About to destroy #{DummyClassifier.count} Dummy classifiers"
    DummyClassifier.find(:all).each do |dc|
      puts "Removing DummyClassifier(#{dc.id})"
      dc.destroy!
    end
  end

  def self.down
  end
end
