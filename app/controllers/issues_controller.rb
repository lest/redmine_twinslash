require_dependency 'issues_controller'

class IssuesController < ApplicationController
  unloadable

  before_filter :find_issue, :only => [:show, :edit, :update, :reply, :copy_to_category_wiki]

  def copy_to_category_wiki
    if request.post?
      if @issue.category
        @wiki_page = @issue.category.create_wiki_page
        @wiki_page.content.text += "\n\nh4. {{issue_subject(#{@issue.id})}}\n\n{{issue_description(#{@issue.id})}}\n"
        @wiki_page.content.author = User.current
        @wiki_page.content.save
        redirect_to :controller => 'wiki', :action => 'edit', :page => @wiki_page.title, :id => @project
      else
        redirect_to :action => 'show', :id => @issue
      end
    else
      redirect_to :action => 'show', :id => @issue
    end
  end
end
