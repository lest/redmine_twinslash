class AddIsQuestionAndOpenedToJournals < ActiveRecord::Migration
  def self.up
    add_column :journals, :is_question, :boolean, :null => false, :default => false
    add_column :journals, :opened,      :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :journals, :is_question
    remove_column :journals, :opened
  end
end
