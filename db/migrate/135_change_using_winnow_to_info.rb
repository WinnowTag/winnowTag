class ChangeUsingWinnowToInfo < ActiveRecord::Migration
  def self.up
    Setting.update_all "name = 'Info'", "name = 'Using Winnow'"
  end

  def self.down
    Setting.update_all "name = 'Using Winnow'", "name = 'Info'"
  end
end
