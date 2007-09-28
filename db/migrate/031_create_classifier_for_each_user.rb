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
