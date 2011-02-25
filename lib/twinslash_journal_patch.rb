module TwinslashJournalPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_many :question_assignments, :dependent => :destroy
      has_many :question_assignees, :class_name => 'User', :through => :question_assignments, :source => :user

      has_many :replies, :class_name => 'Journal', :foreign_key => :reply_to_id, :dependent => :nullify

      named_scope :opened_questions, :conditions => {:is_question => true, :opened => true}

      named_scope :within_project, lambda { |project|
        if project
          {:joins => :issue, :conditions => {:issues => {:project_id => project.id}}}
        else
          {}
        end
      }

      named_scope :with_question_assigned_to, lambda { |user|
        {:joins => :question_assignments, :conditions => {:question_assignments => {:user_id => user.id}}}
      }

      named_scope :author_not_equal, lambda { |user|
        {:conditions => ["#{self.table_name}.user_id != ?", user.id]}
      }

      def journalized_with_twinslash
        obj = journalized_without_twinslash
        def obj.reload
          ids = notify_to_ids
          super
          self.notify_to_ids = ids
          self
        end
        obj
      end

      alias_method_chain :journalized, :twinslash

      def answers_to_question?(question)
        question.is_question? && question.question_assignees.include?(user)
      end

      def css_classes
        css_classes = ['journal'].tap do |css_classes|
          css_classes << 'reply' if reply_to_id
          css_classes << 'question' if is_question?
          css_classes << 'bug' if is_bug?
          css_classes << 'closed' if !opened?
        end
        css_classes.join(' ')
      end
    end
  end
end
