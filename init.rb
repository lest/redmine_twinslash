require 'redmine'

require 'twinslash_form_options_helper_patch'
require 'twinslash_attachment_patch'
require 'twinslash_issues_hooks'

Dispatcher.to_prepare do
  Attachment.send(:include, TwinslashAttachmentPatch)
end

Redmine::Plugin.register :redmine_twinslash do
  name 'Twinslash plugin'
  author 'Just Lest'
  description ''
  version '0.2.0'
end

UPDATABLE_ATTRS_ON_TRANSITION = %w(status_id done_ratio)
