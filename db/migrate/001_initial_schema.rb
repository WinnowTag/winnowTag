# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table "seeds" do |t|
      t.column "url", :string
      t.column "title", :string, :null => true
      t.column "link", :string, :null => true
      t.column "last_xml_data", :longtext
      t.column "last_http_headers", :text
      t.column "time_last_retrieved", :datetime, :null => true
    end
    
    create_table "seed_items" do |t|
      t.column "seed_id", :integer
      t.column "xml_data", :longtext
      t.column "title", :string, :default => ''
      t.column "time", :datetime, :null => true
      t.column "time_retrieved", :datetime, :null => true
      t.column "unique_id", :string, :default => ''
    end
    
    # SBG I don't think this is actually needed but it is in
    #     the original schema so I'm putting it here incase
    create_table "feeds" do |t|
      t.column "url", :string
      t.column "title", :string, :null => true
      t.column "link", :string, :null => true
      t.column "xml_data", :longtext
      t.column "http_headers", :text
      t.column "last_retrieved", :datetime, :null => true
    end
    
    create_table "tags" do |t|
      t.column "name", :string
      t.column "user_id", :integer
    end
    
    # This gets an id since we use JoinClass in acts_as_taggable
    create_table "tags_seed_items" do |t|
      t.column "tag_id", :integer
      t.column "seed_item_id", :string
    end
    
    create_table "users", :force => true do |t|
         t.column "login", :string, :limit => 80, :default => "", :null => false
         t.column "salted_password", :string, :limit => 40, :default => "", :null => false
         t.column "email", :string, :limit => 60, :default => "", :null => false
         t.column "firstname", :string, :limit => 40
         t.column "lastname", :string, :limit => 40
         t.column "salt", :string, :limit => 40, :default => "", :null => false
         t.column "verified", :integer, :default => 0
         t.column "role", :string, :limit => 40
         t.column "security_token", :string, :limit => 40
         t.column "token_expiry", :datetime
         t.column "created_at", :datetime
         t.column "updated_at", :datetime
         t.column "logged_in_at", :datetime
         t.column "deleted", :integer, :default => 0
         t.column "delete_after", :datetime
       end
  end

  def self.down
    drop_table "users"
    drop_table "seeds"
    drop_table "seed_items"
    drop_table "feeds"
    drop_table "tags"
    drop_table "tags_seed_items"
  end
end
