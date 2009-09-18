class TwinslashIssuesHooks < Redmine::Hook::ViewListener
  def view_issues_show_details_bottom(context = {})
    out = ''
    issue = context[:issue]
    if issue.category
      url = url_for(:controller => 'issues',
                    :project_id => issue.project.identifier,
                    :category_id => issue.category.id,
                    :set_filter => 1)
      out = javascript_tag <<JS
var td = $$('.attributes .category')[0].next();
if (td.innerHTML != '-') {
  td.innerHTML = '<a href="#{h url}">' + td.innerHTML + '</a>'
}
JS
    end
    out
  end
end
