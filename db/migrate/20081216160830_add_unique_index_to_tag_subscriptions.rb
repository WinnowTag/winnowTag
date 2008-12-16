class AddUniqueIndexToTagSubscriptions < ActiveRecord::Migration
  class TagSubscription < ActiveRecord::Base; end
  
  def self.up
    TagSubscription.all(:order => "created_at").group_by { |s| "#{s.user_id}-#{s.tag_id}" }.each do |unique_key, tag_subscriptions|
      tag_subscriptions[1..-1].map(&:destroy)
    end
    
    add_index :tag_subscriptions, [:tag_id, :user_id], :unique => true
  end

  def self.down
    remove_index :tag_subscriptions, :column => [:tag_id, :user_id]
  end
end
