# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddSubjectAndBodyToInvites < ActiveRecord::Migration
  def self.up
    add_column :invites, :subject, :string
    add_column :invites, :body, :text
  end

  def self.down
    remove_column :invites, :body
    remove_column :invites, :subject
  end
end
