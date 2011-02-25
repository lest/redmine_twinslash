# -*- coding: utf-8 -*-
module TwinslashQueriesHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :column_content, :twinslash
    end
  end

  module InstanceMethods
    def column_content_with_twinslash(column, issue)
      if column.name == :formatted_questions
        ''.tap do |out|
          out << '<ol>'
          issue.questions.opened_questions.each do |question|
            out << '<li>'
            out << '<div class="tooltip">'
            out << '<span class="question_summary">'
            out << link_to(h(truncate(question.notes, 40)),
                           :controller => 'issues',
                           :action => 'show',
                           :id => question.issue,
                           :anchor => "journal-#{question.id}")
            out << '</span>'
            out << '<span class="tip">'
            out << "<strong>Вопрос от</strong>: #{question.user}<br />"
            out << "<strong>Вопрос для</strong>: #{question.question_assignees.collect(&:to_s).join(', ')}<br />"
            out << "<strong>Создан</strong>: #{format_date(question.created_on)}<br />"
            out << '<br />'
            out << textilizable(question, :notes)
            out << '</span>'
            out << '</div>'
            out << '</li>'
          end
          out << '</ol>'
        end
      else
        column_content_without_twinslash(column, issue)
      end
    end
  end
end
