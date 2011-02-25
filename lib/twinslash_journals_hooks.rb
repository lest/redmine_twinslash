# -*- coding: utf-8 -*-
class TwinslashIssuesHooks < Redmine::Hook::ViewListener
  def view_journals_notes_form_after_notes(context = {})
    journal = context[:journal]
    issue = journal.issue
    ''.tap do |out|
      unless journal.reply_to_id
        radio_buttons = [].tap do |radio_buttons|
          checked_value = case
                          when journal.is_question? then 'question'
                          when journal.is_bug? then 'bug'
                          else 'comment'
                          end
          [['Обновление', 'comment'],
           ['Вопрос', 'question'],
           ['Ошибка', 'bug']].compact.each do |title, value, disabled|
            if value !='bug' || issue.bugs_available?
              radio_buttons << content_tag(:label,
                                           radio_button_tag('journal_type',
                                                            value,
                                                            checked_value == value,
                                                            :disabled => disabled) +
                                           title)
            end
          end
        end
        out << content_tag(:p, radio_buttons.join(' '), :id => 'journal_type')
      end

      if journal.is_question?
        check_boxes = [].tap do |check_boxes|
          issue.project.users.each do |user|
            checked_and_disabled = issue.watcher_users.active.include?(user)
            assigned = journal.question_assignees.include?(user)
            if user.allowed_to?(:view_issues, issue.project)
              check_boxes << content_tag(:label,
                                         check_box_tag('notify_to_ids[]',
                                                       user.id,
                                                       checked_and_disabled || assigned,
                                                       :disabled => checked_and_disabled) +
                                         user.to_s)
            end
          end
        end
        out << content_tag(:p, content_tag(:label, 'Вопрос для') + ' ' + check_boxes.join(' '))
      end
    end
  end

  def controller_journals_edit_post(context = {})
    journal = context[:journal]

    if Journal.exists?(journal.id)
      issue = journal.issue
      params = context[:params]

      if journal.notes.blank?
        params[:journal_type] = 'comment'
      end

      unless journal.reply_to_id
        case params[:journal_type]
        when 'comment'
          journal.is_question = false
          journal.is_bug = false
          journal.opened = true
        when 'question'
          journal.is_question = true
          journal.is_bug = false
        when 'bug'
          if issue.bugs_available?
            journal.is_question = false
            journal.is_bug = true
          end
        end
      end

      if journal.is_question?
        journal.question_assignee_ids = (params[:notify_to_ids] || []) + issue.watcher_users.active.collect(&:id)
      else
        journal.question_assignee_ids = []
      end

      journal.save
    end
  end

  def view_journals_update_rjs_bottom(context = {})
    page = context[:page]
    journal = context[:journal]

    page << "$('change-#{journal.id}').className = '#{escape_javascript(journal.css_classes)}';"
    page.replace_html "journal-#{journal.id}-close-links", :partial => 'close_links', :locals => {:journal => journal}
  end
end
