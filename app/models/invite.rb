class Invite < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :email
  validates_uniqueness_of :email, :message => "has already been submitted"
  
  def initialize(*args, &block)
    super(*args, &block)
    self.subject ||= "Invitation Accepted"
    self.body ||= "You request for an invitation to Winnow has been accepted!"
  end
  
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
      
      paginate(options.merge(
        :select => "invites.*, (CASE WHEN user_id IS NOT NULL THEN 2 WHEN code IS NOT NULL THEN 1 ELSE 0 END) AS status",
        :conditions => conditions))
    end
  end
end
