module RedmineWikiToc
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_wiki_pages_sidebar_end, :partial => 'wiki_toc/sidebar'
  end
end