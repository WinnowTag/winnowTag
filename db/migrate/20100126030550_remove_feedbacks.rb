# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveFeedbacks < ActiveRecord::Migration
  def self.up
    drop_table :feedbacks
  end

  def self.down
    create_table "feedbacks", :force => true do |t|
      t.text     "body"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
