module TwinslashMailerPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :issue_edit, :twinslash
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def issue_edit_with_twinslash(journal)
      result = issue_edit_without_twinslash(journal)
      if journal.is_question?
        subject subject.sub(/^\[/, '[Question - ')
      elsif journal.reply_to_id
        replied_journal = Journal.find(journal.reply_to_id)
        if replied_journal && journal.answers_to_question?(replied_journal)
          subject subject.sub(/^\[/, '[Answer - ')
        end
      end
      result
    end
  end
end
