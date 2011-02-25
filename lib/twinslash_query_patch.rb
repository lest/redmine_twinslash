module TwinslashQueryPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      alias_method_chain :available_filters, :twinslash
      alias_method_chain :sql_for_field, :twinslash

      base.add_available_column(QueryColumn.new(:formatted_questions))
    end
  end

  module InstanceMethods
    def available_filters_with_twinslash
      filters = available_filters_without_twinslash

      filters.merge!('in_current_versions' => {:type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 14})

      user_values = []
      user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
      if project
        user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
      else
        user_values += User.current.projects.collect(&:users).flatten.uniq.sort.collect{|s| [s.name, s.id.to_s] }
      end

      filters.merge!('question_author_id' => {:type => :list, :values => user_values, :order => 14})
      filters.merge!('question_assignee_id' => {:type => :list, :values => user_values, :order => 14})
      filters.merge!('question_answer_for' => {:type => :list, :values => user_values, :order => 14})

      ['question', 'bug'].each do |type|
        filters.merge!("has_#{type}" => {:type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 14})
      end

      filters
    end

    def sql_for_field_with_twinslash(*args)
      field, operator = args
      case field

      when 'in_current_versions'
        scope = project && project.shared_versions || Version
        version_ids = scope.open.visible.all(:conditions => 'effective_date IS NOT NULL').collect(&:id).push(0)

        if operator == '='
          "#{Issue.table_name}.fixed_version_id IN (#{version_ids.join(',')})"
        else
          "#{Issue.table_name}.fixed_version_id IS NULL OR #{Issue.table_name}.fixed_version_id NOT IN (#{version_ids.join(',')})"
        end

      when 'question_author_id', 'question_assignee_id'
        journal_table = Journal.table_name
        values = values_for(field).clone
        values.push(User.current.logged? ? User.current.id.to_s : '0') if values.delete('me')
        quoted_values = values.collect{ |v| "'#{connection.quote_string(v)}'" }

        sql = "#{journal_table}.is_question = 1 AND #{journal_table}.opened = 1 AND "

        case field
        when 'question_author_id'
          sql << "#{journal_table}.user_id IN (#{quoted_values.join(',')})"
        when 'question_assignee_id'
          sql << "#{QuestionAssignment.table_name}.user_id IN (#{quoted_values.join(',')})"
        end

        sql

      when 'question_answer_for'
        journal_table = Journal.table_name
        values = values_for(field).clone
        values.push(User.current.logged? ? User.current.id.to_s : '0') if values.delete('me')
        quoted_values = values.collect{ |v| "'#{connection.quote_string(v)}'" }

        question_ids = Journal.all(:select => "#{Journal.table_name}.id",
                                   :conditions => {
                                     :is_question => true,
                                     :opened => true,
                                     :user_id => values
                                   }).collect(&:id)

        if question_ids.any?
          "#{journal_table}.reply_to_id IN (#{question_ids.join(',')}) AND #{journal_table}.user_id NOT IN (#{quoted_values})"
        else
          '1 = 0'
        end

      when 'has_question', 'has_bug'
        journal_table = Journal.table_name
        flag_field = field.gsub(/^has_/, 'is_')

        if operator == '='
          "#{journal_table}.#{flag_field} = 1 && #{journal_table}.opened = 1"
        else
          "#{journal_table}.#{flag_field} IS NULL OR #{journal_table}.#{flag_field} = 0 OR #{journal_table}.opened = 0"
        end

      else
        sql_for_field_without_twinslash(*args)
      end
    end
  end
end
