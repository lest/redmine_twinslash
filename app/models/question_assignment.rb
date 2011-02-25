class QuestionAssignment < ActiveRecord::Base
  unloadable

  belongs_to :journal
  belongs_to :user
end
