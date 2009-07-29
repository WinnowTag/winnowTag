# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents feedback submitted by a User.
class Feedback < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user_id, :body
  
  named_scope :matching, lambda { |q|
    conditions = %w[feedbacks.body users.login].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :include => :user, :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  named_scope :by, lambda { |order, direction|
    orders = {
      "id"         => "feedbacks.id",
      "created_at" => "feedbacks.created_at",
      "user"       => "users.login"
    }
    orders.default = "feedbacks.created_at"
    
    directions = {
      "asc" => "ASC",
      "desc" => "DESC"
    }
    directions.default = "ASC"
    
    { :include => :user, :order => [orders[order], directions[direction]].join(" ") }
  }

  def self.search(options = {})
    scope = by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(:limit => options[:limit], :offset => options[:offset])
  end
end
