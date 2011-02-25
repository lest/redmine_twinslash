class CreateQuestionAssignments < ActiveRecord::Migration
  def self.up
    create_table :question_assignments do |t|
      t.integer :journal_id, :null => false
      t.integer :user_id,    :null => false
    end
  end

  def self.down
    drop_table :question_assignments
  end
end
