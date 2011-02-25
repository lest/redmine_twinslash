class AddIsBugToJournals < ActiveRecord::Migration
  def self.up
    add_column :journals, :is_bug, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :journals, :is_bug
  end
end
