# -*- coding: utf-8 -*-
class TwinslashIssuesHooks < Redmine::Hook::ViewListener
  def view_issues_show_details_bottom(context = {})
    out = ''
    issue = context[:issue]
    if issue.category
      url = url_for(:controller => 'issues',
                    :project_id => issue.project.identifier,
                    :category_id => issue.category.id,
                    :set_filter => 1)
      out = javascript_tag <<JS
var td = $$('.attributes .category')[0].next();
if (td.innerHTML != '-') {
  td.innerHTML = '<a href="#{h url}">' + td.innerHTML + '</a>'
}
JS
    end
    out
  end

  def controller_issues_bulk_edit_before_save(context = {})
    context[:issue].start_date = nil if context[:params][:start_date] == 'none'
    context[:issue].due_date = nil if context[:params][:due_date] == 'none'
  end

  def view_issues_edit_notes_bottom(context = {})
    ''.tap do |out|
      out << hidden_field_tag('journal_reply_to_id')

      issue = context[:issue]

      out << content_tag(:p,
                         content_tag(:label,
                                     radio_button_tag('journal_type', 'comment', true) +
                                     'Обновление') + ' ' +
                         content_tag(:label,
                                     radio_button_tag('journal_type', 'reply') +
                                     'Ответ') + ' ' +

                         content_tag(:label,
                                      radio_button_tag('journal_type', 'question') +
                                     'Вопрос') + ' ' +
                         (issue.bugs_available? ?
                         content_tag(:label,
                                     radio_button_tag('journal_type', 'bug') +
                                     'Ошибка') : ''),
                         :id => 'journal_type')

      check_boxes = ''
      issue.project.users.each do |user|
        checked_and_disabled = issue.watcher_users.active.include?(user)
        if user.allowed_to?(:view_issues, issue.project)
          check_boxes << content_tag(:label,
                                     check_box_tag('notify_to_ids[]',
                                                   user.id,
                                                   checked_and_disabled,
                                                   :disabled => checked_and_disabled) +
                                     user.to_s) + ' '
        end
      end
      out << content_tag(:p, content_tag(:label, 'Уведомление/вопрос для') + ' ' + check_boxes)
    end
  end

  def controller_issues_edit_before_save(context = {})
    params = context[:params]
    journal = context[:journal]
    issue = context[:issue]

    if params[:journal_type] == 'reply'
      replied_journal = Journal.find_by_id(params[:journal_reply_to_id])
      if replied_journal && replied_journal.issue == issue
        journal.reply_to_id = replied_journal.reply_to_id || replied_journal.id
      end
    end

    issue.notify_to_ids = params[:notify_to_ids]

    if params[:journal_type] == 'question'
      journal.is_question = true
      journal.question_assignee_ids = (params[:notify_to_ids] || []) + issue.watcher_users.active.collect(&:id)
    end

    if params[:journal_type] == 'bug' && issue.bugs_available?
      journal.is_bug = true
    end
  end

  def view_issues_sidebar_issues_bottom(context = {})
    project = context[:project]

    ''.tap do |out|
      question_scope = Journal.opened_questions.within_project(project)

      question_count = question_scope.with_question_assigned_to(User.current).count(:select => :journalized_id, :distinct => true)

      if question_count > 0
        out << link_to("Вопросы для меня (#{question_count})",
                       :controller => 'issues', :project_id => project && project.id, :set_filter => 1, :question_assignee_id => 'me') + '<br />'
      end

      question_ids = question_scope.all(:select => "#{Journal.table_name}.id",
                                        :conditions => {:user_id => User.current.id}).collect(&:id)
      answer_count = Journal.author_not_equal(User.current).count(:select => :journalized_id, :distinct => true, :conditions => {:reply_to_id => question_ids})

      if answer_count > 0
        out << link_to("Ответы на мои вопросы (#{answer_count})",
                       :controller => 'issues', :project_id => project && project.id, :set_filter => 1, :question_answer_for => 'me') + '<br />'
      end
    end
  end
end
