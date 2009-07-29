# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents inviting someone to Winnow
class Invite < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :email

  def initialize(*args, &block)
    super(*args, &block)
    self.subject ||= I18n.t("winnow.invites.edit.default_accepted_subject")
    self.body ||= I18n.t("winnow.invites.edit.default_accepted_body")
  end
  
  def activate!
    self.update_attribute :code, MD5.hexdigest("#{email}--#{Time.now}--#{rand}")
  end

  named_scope :matching, lambda { |q|
    conditions = %w[invites.email].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  named_scope :by, lambda { |order, direction|
    orders = {
      "id"         => "invites.id",
      "email"      => "invites.email",
      "created_at" => "invites.created_at",
      "status"     => "CASE WHEN invites.user_id IS NOT NULL THEN 2 WHEN invites.code IS NOT NULL THEN 1 ELSE 0 END"
    }
    orders.default = "invites.created_at"
    
    directions = {
      "asc" => "ASC",
      "desc" => "DESC"
    }
    directions.default = "ASC"
    
    { :order => [orders[order], directions[direction]].join(" ") }
  }

  def self.search(options = {})
    scope = by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(:limit => options[:limit], :offset => options[:offset])
  end

  def self.active(code)
    find(:first, :conditions => ["code = ? AND code IS NOT NULL AND code != '' AND user_id IS NULL", code.to_s])
  end
end
