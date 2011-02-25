module ActionView
  module Helpers
    module PrototypeHelper
      def link_to_remote_with_twinslash(name, options = {}, html_options = nil)
        if options[:url].is_a?(Hash) && options[:url][:controller] == 'issues' && options[:url][:action] == 'reply'
          existing_callback = options[:success] || ''

          options[:success] = ''
          options[:success] << "$('journal_reply_to_id').value = '#{options[:url][:journal_id].to_param}';"
          options[:success] << "$('journal_type_reply').disabled = false;"
          options[:success] << "$('journal_type_reply').checked = true;"
          options[:success] << "$$('input#notify_to_ids_').each(function (input) { if (!input.disabled) input.checked = false; });"

          journal = Journal.find(options[:url][:journal_id])
          if journal.is_question?
            ([journal.user] + journal.question_assignees).each do |user|
              options[:success] << "$$('input#notify_to_ids_[value=#{user.id}]').each(function (input) { input.checked = true; });"
            end
          end

          options[:success] << existing_callback
        end
        link_to_remote_without_twinslash(name, options, html_options)
      end
      alias_method_chain :link_to_remote, :twinslash
    end
  end
end
