class Invite < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :email
  validates_uniqueness_of :email
  
  def activate!
    require 'md5'
    self.update_attribute :code, MD5.hexdigest("#{email}--#{Time.now}--#{rand}")
  end

  class << self
    def find_active(code)
      find(:first, :conditions => ["code = ? AND code IS NOT NULL AND code != '' AND user_id IS NULL", code.to_s])
    end
  end
end
