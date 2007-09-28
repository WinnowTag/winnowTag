# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Stores the options used for the execution of the classifier. This can be
# attached to the metadata association of the tagging so we can find out
# the classifier parameters that were used to generate a tagging.
#
#== Schema Information
# Schema version: 57
#
# Table name: classifier_executions
#
#  id                     :integer(11)   not null, primary key
#  created_on             :datetime      
#  default_bias           :float         default(1.0)
#  min_prob_strength      :float         
#  max_discriminators     :integer(11)   
#  unknown_word_strength  :float         
#  unknown_word_prob      :float         
#  min_train_count        :integer(11)   
#  bayes_classifier_id    :integer(11)   
#  positive_cutoff        :float         
#  only                   :text           
#  random_background_size :integer(11)   
#  insertion_cutoff       :float         
#  min_token_count        :integer(11)   default(20)
#  bias                   :text          
#

class ClassifierExecution < ActiveRecord::Base
  serialize :only, Array
  serialize :bias, Hash
  belongs_to :classifier, :class_name => "BayesClassifier", :foreign_key => "bayes_classifier_id"
  has_many :taggings, :as => :metadata

  # Returns a Hash of classification options.
  #
  # See also BayesClassifier#classification_options.
  #
  def classification_options
    unless @classification_options
      @classification_options = self.attributes.symbolize_keys
      if @classification_options[:bias].nil?
        @classification_options[:bias] = {}
      end
      @classification_options[:bias].default = self.default_bias
    end
    
    @classification_options
  end
  
  # Returns the bias Hash with the default bias set.
  #
  # See also BayesClassifier#bias
  def bias
    bias = read_attribute(:bias)
    if bias.nil?
      bias = self.bias = {}
    end
    bias.default = default_bias
    bias
  end
  
  protected
  # Copies across classifier options from the BayesClassifier instance
  # this belongs to.
  #
  def before_create
    if self.classifier
      self.attributes = self.classifier.classification_options
    else
      self.classification_cutoff ||= BayesClassifier.cutoff
    end
  end
end
