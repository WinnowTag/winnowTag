class AddSphinxSearchTable < ActiveRecord::Migration
  def self.up
    execute %|
      CREATE TABLE feed_item_search (
        id          INTEGER NOT NULL,
        weight      INTEGER NOT NULL,
        query       VARCHAR(3072) NOT NULL,
        INDEX(query)
      ) ENGINE=SPHINX CONNECTION="sphinx://localhost:3313/main";
    |
    # title       INTEGER,
    # author      INTEGER,
    # content     INTEGER,
  end

  def self.down
    drop_table :feed_item_search
  end
end
