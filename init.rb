require 'redmine'

require 'twinslash_form_options_helper_patch'
require 'twinslash_attachment_patch'

Dispatcher.to_prepare do
  Attachment.send(:include, TwinslashAttachmentPatch)
end

Redmine::Plugin.register :redmine_twinslash do
  name 'Redmine Twinslash plugin'
  author 'Just Lest'
  description ''
  version '0.0.2'
end
