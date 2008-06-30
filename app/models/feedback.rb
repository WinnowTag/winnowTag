# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Feedback < ActiveRecord::Base
  belongs_to :user
  
  class << self
    def search(options = {})
      conditions, values = [], []
      
      unless options[:text_filter].blank?
        ored_conditions = []
        %w[feedbacks.body users.login users.firstname users.lastname users.email].each do |attribute|
          ored_conditions << "#{attribute} LIKE ?"
          values          << "%#{options[:text_filter]}%"
        end
        conditions << "(" + ored_conditions.join(" OR ") + ")"
      end
      
      direction = case options[:direction]
      when "asc", "desc"
        options[:direction].upcase
      end

      order = case options[:order]
      when "created_at", "id"
        "feedbacks.#{options[:order]} #{direction}"
      when "user"
        "users.login #{direction}"
      else
        "feedbacks.created_at"
      end
    
      options_for_find = { :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values],
                           :joins => "LEFT JOIN users ON users.id = feedbacks.user_id" }
      
      results = find(:all, options_for_find.merge(
                     :order => order, :limit => options[:limit], :offset => options[:offset]))
      
      if options[:count]
        [results, count(options_for_find)]
      else
        results
      end
    end
  end
end
