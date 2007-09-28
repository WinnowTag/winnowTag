# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
# == Schema Information
# Schema version: 57
#
# Table name: roles
#
#  id                :integer(11)   not null, primary key
#  name              :string(40)    
#  authorizable_type :string(30)    
#  authorizable_id   :integer(11)   
#  created_at        :datetime      
#  updated_at        :datetime      
#

class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :authorizable, :polymorphic => true
  
  def self.delete_all_non_admin_roles!
    connection.delete "delete from roles_users where role_id in (select id from roles where name <> 'admin');"
    delete_all "name <> 'admin'"
  end
end
