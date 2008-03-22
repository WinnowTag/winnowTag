class Folder < ActiveRecord::Base
  belongs_to :user
  
  validates_uniqueness_of :name, :scope => :user_id
  
  def feed_ids
    read_attribute(:feed_ids).to_s.split(",").map(&:to_i)
  end
  
  def tag_ids
    read_attribute(:tag_ids).to_s.split(",").map(&:to_i)
  end
  
  def feed_ids=(feed_ids)
    write_attribute(:feed_ids, feed_ids.map(&:to_s).uniq.join(","))
  end
  
  def tag_ids=(tag_ids)
    write_attribute(:tag_ids, tag_ids.map(&:to_s).uniq.join(","))
  end
  
  def feeds
    Feed.find_all_by_id(feed_ids, :order => :title)
  end
  
  def tags
    Tag.find_all_by_id(tag_ids, :order => :name)
  end
end
