module ActionView
  module Helpers
    module AssetTagHelper
      def javascript_include_tag_with_twinslash(*sources)
        out = javascript_include_tag_without_twinslash(*sources)
        if sources.is_a?(Array) and sources[0] == 'jstoolbar/textile'
          out += javascript_tag <<-javascript_tag
jsToolBar.prototype.elements.issue_subject = {
	type: 'button',
	title: 'Issue subject',
	fn: {
		wiki: function() { this.encloseSelection("{{issue_subject(", ")}}") }
	}
}
javascript_tag
          out += stylesheet_link_tag 'twinslash', :plugin => 'redmine_twinslash_core'
        end
        out
      end
      alias_method_chain :javascript_include_tag, :twinslash
    end
  end
end
