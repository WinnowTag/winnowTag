# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateClassifierForEachUser < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |u|
      u.classifier = BayesClassifier.new if u.classifier.nil?
      u.save
    end
  end

  def self.down
  end
end
