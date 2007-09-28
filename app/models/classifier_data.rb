# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Used for storing training data of the a classifier.
#
# == Schema Information
# Schema version: 57
#
# Table name: classifier_datas
#
#  id                  :integer(11)   not null, primary key
#  bayes_classifier_id :integer(11)   not null
#  data                :text          
#  created_on          :datetime      
#  updated_on          :datetime      
#

class ClassifierData < ActiveRecord::Base
  belongs_to :bayes_classifier
end
