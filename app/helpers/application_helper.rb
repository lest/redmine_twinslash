require_dependency 'application_helper'

module ApplicationHelper
  def link_to_remote_if_authorized_with_twinslash(name, options = {}, html_options = nil)
    result = ''
    if options[:url] && options[:url][:action] == 'reply' && options[:url][:id] && (issue = Issue.find(options[:url][:id])) && issue.category
      wiki_page = issue.project.wiki.find_page(issue.category.name)
      is_included = wiki_page && wiki_page.content.text.include?("{{issue_subject(#{@issue.id})}}")
      result += link_to_if_authorized(l(is_included ? :text_recopy_to_category_wiki : :text_copy_to_category_wiki),
                                     {:controller => 'issues', :action => 'copy_to_category_wiki', :id => options[:url][:id]},
                                     :method => :post, :class => 'icon icon-copy', :style => 'margin-right: .5em;').to_s
    end
    result += link_to_remote_if_authorized_without_twinslash(name, options, html_options).to_s
    result
  end

  alias_method_chain :link_to_remote_if_authorized, :twinslash
end
