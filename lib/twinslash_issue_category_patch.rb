require_dependency 'issue_category'

module TwinslashIssueCategoryPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      before_save :store_previous_name
      after_save :create_wiki_page
    end
  end

  module InstanceMethods
    def store_previous_name
      @previous_name = self.name_was
    end

    def create_wiki_page
      wiki = self.project.wiki
      features_page = wiki.find_or_new_page('Features')
      if features_page.new_record?
        features_page.save
        WikiContent.create!(:page => features_page, :text => '{{child_pages}}')
      end
      page = nil
      page = wiki.find_page(@previous_name) unless @previous_name.blank?
      page ||= wiki.find_or_new_page(self.name)
      page.parent = features_page
      old_page_title = page.title
      page.title = self.name
      if page.new_record?
        page.save
        WikiContent.create!(:page => page, :text => "h1. #{page.title}")
      else
        page.save
        page.update_attribute(:title, old_page_title) if old_page_title != @previous_name
      end
      page.reload
      page
    end
  end
end
