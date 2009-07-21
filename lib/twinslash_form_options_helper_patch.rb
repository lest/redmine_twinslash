module ActionView
  module Helpers
    module FormOptionsHelper
      def select_with_twinslash(object, method, choices, options = {}, html_options = {})
        if (object == :issue and method == :fixed_version_id)
          ids = choices.collect {|it| it[1]}
          versions = Version.find(:all, :conditions => ['id in (?)', ids])
          choices = versions.select {|it| not it.completed?}.sort.collect {|it| [it.name, it.id]}
        end
        select_without_twinslash(object, method, choices, options, html_options)
      end
      
      def options_from_collection_for_select_with_twinslash(collection, value_method, text_method, selected = nil)
        if collection and collection[0].class == Version
          collection = collection.select {|it| not it.completed?}.sort
        end
        options_from_collection_for_select_without_twinslash(collection, value_method, text_method, selected)
      end
      
      alias_method_chain :select, :twinslash
      alias_method_chain :options_from_collection_for_select, :twinslash
    end
  end
end
