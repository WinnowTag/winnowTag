class Invite < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :email
  validates_uniqueness_of :email, :message => "has already been submitted"
  
  def activate!
    require 'md5'
    self.update_attribute :code, MD5.hexdigest("#{email}--#{Time.now}--#{rand}")
  end

  class << self
    def find_active(code)
      find(:first, :conditions => ["code = ? AND code IS NOT NULL AND code != '' AND user_id IS NULL", code.to_s])
    end

    def search(options = {})
      conditions, values = [], []
      
      q = options.delete(:q)
      unless q.blank?
        ored_conditions = []
        [:email].each do |attribute|
          ored_conditions << "invites.#{attribute} LIKE ?"
          values          << "%#{q}%"
        end
        conditions << "(" + ored_conditions.join(" OR ") + ")"
      end
      
      conditions = conditions.empty? ? nil : [conditions.join(" AND "), *values]
      
      paginate(options.merge(:conditions => conditions))
    end
  end
end
