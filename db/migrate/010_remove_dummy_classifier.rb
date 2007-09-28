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
