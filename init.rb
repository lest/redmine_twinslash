require 'redmine'

require 'twinslash_issues_hooks'
require 'twinslash_journals_hooks'

require 'twinslash_asset_tag_helper_patch'
require 'twinslash_prototype_helper_patch'

Dispatcher.to_prepare do
  require_dependency 'attachment'
  Attachment.send(:include, TwinslashAttachmentPatch) unless Attachment.included_modules.include?(TwinslashAttachmentPatch)

  require_dependency 'issue_category'
  IssueCategory.send(:include, TwinslashIssueCategoryPatch) unless IssueCategory.included_modules.include?(TwinslashIssueCategoryPatch)

  require_dependency 'issue'
  Issue.send(:include, TwinslashIssuePatch) unless Issue.included_modules.include?(TwinslashIssuePatch)

  require_dependency 'journal'
  Journal.send(:include, TwinslashJournalPatch) unless Journal.included_modules.include?(TwinslashJournalPatch)

  require_dependency 'query'
  Query.send(:include, TwinslashQueryPatch) unless Query.included_modules.include?(TwinslashQueryPatch)

  require_dependency 'mailer'
  Mailer.send(:include, TwinslashMailerPatch) unless Mailer.included_modules.include?(TwinslashMailerPatch)

  require_dependency 'queries_helper'
  QueriesHelper.send(:include, TwinslashQueriesHelperPatch) unless QueriesHelper.included_modules.include?(TwinslashQueriesHelperPatch)
end

Redmine::Plugin.register :redmine_twinslash_core do
  name 'Twinslash plugin'
  author 'Just Lest'
  description ''
  version '0.4.0'

  permission :copy_issue_to_category_wiki, {:issues => :copy_to_category_wiki}
  permission :close_question, {}
  permission :close_bug, {:journals => :close_bug}

  settings :default => {:bug_trackers => []}, :partial => 'settings/twinslash_settings'
end

UPDATABLE_ATTRS_ON_TRANSITION = %w(status_id done_ratio)

Redmine::WikiFormatting::Macros.register do
  desc 'Issue subject'
  macro :issue_subject do |obj, args|
    issue = obj.project.issues.find(args[0])
    if User.current.allowed_to?(:view_issues, issue.project)
      "#{h issue.tracker} ##{issue.id} #{h issue.subject} (#{h issue.status})"
    else
      "##{issue.id} #{h issue.subject}"
    end
  end

  desc 'Issue description'
  macro :issue_description do |obj, args|
    issue = obj.project.issues.find(args[0])
    @included_issue_descriptions ||= []
    raise 'Circular inclusion detected' if @included_issue_descriptions.include?(issue.id)
    @included_issue_descriptions << issue.id
    out = textilizable(issue, :description, :attachments => issue.attachments)
    @included_issue_descriptions.pop
    if User.current.allowed_to?(:view_issues, issue.project)
      out
    else
      ''
    end
  end

  desc 'Issue children'
  macro :issue_children do |obj, args|
    issue = obj.project.issues.find(args[0])
    if User.current.allowed_to?(:view_issues, issue.project)
      issue.children.reduce('') do |out, child|
        out << textilizable((<<TXT
* {{issue_subject(#{child.id})}}

  {{issue_description(#{child.id})}}
TXT
                             ), :object => issue)
      end
    else
      ''
    end
  end

  desc 'Version information'
  macro :version_info do |obj, args|
    version = obj.project.shared_versions.find_by_name(args[0])
    if version
      out = ''
      if version.effective_date
        out << "<b>#{format_date(version.effective_date)}</b>"
        out << " - "
      end
      out << link_to(h(version.name), :controller => 'versions', :action => 'show', :id => version)
      if version.description.present?
        out << " - "
        wiki_page = version.project.wiki.find_page(version.wiki_page_title)
        if wiki_page
          out << link_to(h(version.description), :controller => 'wiki', :action => 'index', :id => version.project, :page => wiki_page.title)
        else
          out << h(version.description)
        end
      end
      out
    end
  end

  desc 'User information'
  macro :user_info do |obj, args|
    user = User.find_by_login(args[0])
    user && "#{h([user.firstname, user.lastname].join(' '))} (#{link_to(h(user.login), :controller => 'users', :action => 'show', :id => user)})"
  end

  desc 'Journal notes'
  macro :journal_notes do |obj, args|
    issue = Issue.find(args[0])
    journals = issue.journals.find(:all, :order => "#{Journal.table_name}.created_on ASC")
    journal = journals[args[1].to_i - 1]
    @included_journal_notes ||= []
    raise 'Circular inclusion detected' if @included_journal_notes.include?(journal.id)
    @included_journal_notes << journal.id
    out = textilizable(journal, :notes, :attachments => issue.attachments)
    @included_journal_notes.pop
    if User.current.allowed_to?(:view_issues, issue.project)
      out
    else
      ''
    end
  end
end
