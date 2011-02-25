require_dependency 'journals_controller'

class JournalsController < ApplicationController
  unloadable

  def close_question
    if @journal.user == User.current || User.current.allowed_to?(:close_question, @journal.project)
      @journal.update_attribute(:opened, params[:closed] != 'true')
    end
    render :action => 'close_journal'
  end

  def close_bug
    @journal.update_attribute(:opened, params[:closed] != 'true')
    render :action => 'close_journal'
  end
end
