class RemoveTagPublications < ActiveRecord::Migration
  def self.up
    # TODO: Not sure if tag_publications can be salvaged at this point... the tag_id is likely out of date
    drop_table :tag_publications    
  end

  def self.down
    create_table :tag_publications do |t|
      t.column :publisher_id, :integer
      t.column :tag_id, :integer
      t.column :comment, :text
      t.column :created_on, :datetime
    end
  end
end
