# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateClassifiers < ActiveRecord::Migration
  def self.up
    create_table "classifiers" do |t|
      t.column "type", :string, :null => false
      t.column "version", :string, :null => false, :default => '1'
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
      t.column "last_executed", :datetime
      t.column "deleted_at", :datetime
      t.column "mode", :string
      t.column "data", :text
    end
    
    create_table "classifiers_users", :id => false do |t|
      t.column "classifier_id", :integer, :null => false
      t.column "user_id", :integer, :null => false
    end
    
    create_table "classifiers_tags", :id => false do |t|
      t.column "classifier_id", :integer, :null => false
      t.column "tag_id", :integer, :null => false
    end
  end

  def self.down
    drop_table "classifiers"
    drop_table "classifiers_users"
    drop_table "table"
  end
end
