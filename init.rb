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
  version '0.3.3'

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
end
