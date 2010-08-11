require 'redmine'

require 'twinslash_attachment_patch'
require 'twinslash_issue_category_patch'

require 'twinslash_issues_hooks'

require 'twinslash_asset_tag_helper_patch'

Dispatcher.to_prepare do
  Attachment.send(:include, TwinslashAttachmentPatch) unless Attachment.included_modules.include?(TwinslashAttachmentPatch)
  IssueCategory.send(:include, TwinslashIssueCategoryPatch) unless IssueCategory.included_modules.include?(TwinslashIssueCategoryPatch)
end

Redmine::Plugin.register :redmine_twinslash_core do
  name 'Twinslash plugin'
  author 'Just Lest'
  description ''
  version '0.3.4'

  permission :copy_issue_to_category_wiki, {:issues => :copy_to_category_wiki}
end

UPDATABLE_ATTRS_ON_TRANSITION = %w(status_id done_ratio)

Redmine::WikiFormatting::Macros.register do
  desc 'Issue subject'
  macro :issue_subject do |obj, args|
    issue = obj.project.issues.find(args[0])
    link_to "!##{issue.id} #{h issue.subject}", :controller => 'issues', :action => 'show', :id => issue
  end

  desc 'Issue description'
  macro :issue_description do |obj, args|
    issue = obj.project.issues.find(args[0])
    textilizable issue, :description, :attachments => issue.attachments
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
end
