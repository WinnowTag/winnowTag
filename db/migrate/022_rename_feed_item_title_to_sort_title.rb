class RenameFeedItemTitleToSortTitle < ActiveRecord::Migration
  def self.up    
    FeedItem.transaction do
      rename_column "feed_items", "title", "sort_title"
      execute "update feed_items set sort_title = TRIM(LEADING 'an ' from TRIM(LEADING 'a ' from TRIM(LEADING 'the ' from LCASE(sort_title))));"
      
      FeedItem.find(:all, :conditions => "sort_title is null or sort_title = ''").each do |fi|
        execute "update feed_items set sort_title = TRIM(LEADING 'an ' from TRIM(LEADING 'a ' from TRIM(LEADING 'the ' from LCASE(#{quote(fi.display_title)})))) where id = #{fi.id};"
      end
    end
  end

  def self.down
     raise ActiveRecord::IrreversibleMigration, 'Unable to restore sort titles'
  end
  
  def self.quote(o)
    ActiveRecord::Base.connection.quote(o)
  end
end
