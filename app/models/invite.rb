# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class Invite < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :email
  # TODO: localization
  validates_uniqueness_of :email, :message => "has already been submitted"
  
  def initialize(*args, &block)
    super(*args, &block)
    self.subject ||= _(:default_invite_accepted_subject)
    self.body ||= _(:default_invite_accepted_body)
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
      
      unless options[:text_filter].blank?
        ored_conditions = []
        [:email].each do |attribute|
          ored_conditions << "invites.#{attribute} LIKE ?"
          values          << "%#{options[:text_filter]}%"
        end
        conditions << "(" + ored_conditions.join(" OR ") + ")"
      end

      order = case options[:order]
      when "created_at", "email", "id"
        "invites.#{options[:order]}"
      when "status"
        options[:order]
      else
        "invites.created_at"
      end
      
      case options[:direction]
      when "asc", "desc"
        order = "#{order} #{options[:direction].upcase}"
      end

      options_for_find = { :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values] }
      
      results = find(:all, options_for_find.merge(
                     :select => "invites.*, (CASE WHEN user_id IS NOT NULL THEN 2 WHEN code IS NOT NULL THEN 1 ELSE 0 END) AS status",
                     :order => order, :limit => options[:limit], :offset => options[:offset]))
      
      if options[:count]
        [results, count(options_for_find)]
      else
        results
      end
    end
  end
end
