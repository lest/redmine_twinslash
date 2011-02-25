module TwinslashIssuePatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      attr_accessor :notify_to_ids
      alias_method_chain :watcher_recipients, :twinslash

      has_many :questions, :class_name => 'Journal', :as => :journalized, :conditions => "#{Journal.table_name}.is_question = 1"
      has_many :question_assignments, :through => :questions

      class << self
        alias_method_chain :find, :twinslash
        alias_method_chain :count, :twinslash
        alias_method_chain :sum, :twinslash
      end
    end
  end

  module ClassMethods
    def find_with_twinslash(*args)
      scan_for_options_hash_and_add_includes_if_needed(args)
      find_without_twinslash(*args)
    end

    def count_with_twinslash(*args)
      scan_for_options_hash_and_add_includes_if_needed(args)
      count_without_twinslash(*args)
    end

    def sum_with_twinslash(*args)
      scan_for_options_hash_and_add_includes_if_needed(args)
      sum_without_twinslash(*args)
    end

    private

    # Finds the options hash. If question is part of the conditions then
    # add questions to the includes
    def scan_for_options_hash_and_add_includes_if_needed(args)
      args.each do |arg|
        if arg.is_a?(Hash) && arg[:conditions]
          condition = if arg[:conditions].is_a?(String)
                        arg[:conditions]
                      elsif arg[:conditions].is_a?(Array)
                        arg[:conditions][0]
                      end
          if condition
            add_journals_to_the_includes(arg, :journals) if condition.include?(Journal.table_name)
            add_journals_to_the_includes(arg, :question_assignments) if condition.include?(QuestionAssignment.table_name)
          end
        end
      end
    end

    def add_journals_to_the_includes(arg, association)
      if arg[:include]
        # Has includes
        if arg[:include].is_a?(Hash)
          # Hash includes
          arg[:include] << association
        else
          # single includes
          arg[:include] = [arg[:include] , association]
        end
      else
        # No includes
        arg[:include] = association
      end
    end
  end

  module InstanceMethods
    def bugs_available?
      bug_trackers = Setting.plugin_redmine_twinslash_core['bug_trackers'] || []
      bug_trackers.include?(tracker_id.to_s)
    end

    def watcher_recipients_with_twinslash
      mails = watcher_recipients_without_twinslash
      if notify_to_ids && notify_to_ids.is_a?(Array)
        notify_to_ids.each do |id|
          user = User.active.find_by_id(id)
          if user && user.allowed_to?(:view_issues, project)
            mails << user.mail
          end
        end
      end
      mails.compact.uniq
    end
  end
end
