# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class StoreTokensInDatabase < ActiveRecord::Migration
  def self.up
    create_table :tokens, :options => 'ENGINE=MyISAM' do |t|
      t.column :token, :string
    end
    
    token_file = File.expand_path(File.join(RAILS_ROOT, 'log', 'tokens.log'))
    
    if File.exists?(token_file)
      say("About to load #{token_file} into database. This could take a while...")
      execute("load data infile '#{token_file}' into table tokens fields terminated by ',';")
      say("#{token_file} has been loaded into the database.  You can delete it but reversing"+
          " this migration won't recreate it, so make sure you don't need it first.")
    end
  end

  def self.down
    drop_table :tokens
  end
end
