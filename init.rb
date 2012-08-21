require 'redmine_wiki_toc/macros'
require 'redmine_wiki_toc/hooks'

Rails.configuration.to_prepare do
  unless ActionView::Base.include?(RedmineWikiToc::Helper)
    ActionView::Base.send :include, RedmineWikiToc::Helper
  end
  unless WikiPage.include?(RedmineWikiToc::WikiPagePatch)
    WikiPage.send :include, RedmineWikiToc::WikiPagePatch
  end
  unless WikiController.include?(RedmineWikiToc::WikiControllerPatch)
    WikiController.send :include, RedmineWikiToc::WikiControllerPatch
  end
  unless WikiHelper.include?(RedmineWikiToc::WikiHelperPatch)
    WikiHelper.send :include, RedmineWikiToc::WikiHelperPatch
  end
  unless ApplicationHelper.include?(RedmineWikiToc::ApplicationHelperPatch)
    ApplicationHelper.send :include, RedmineWikiToc::ApplicationHelperPatch
  end
end

Redmine::Plugin.register :redmine_wiki_toc do
  name 'Redmine Wiki table of contents plugin'
  author 'Anton Argirov'
  author_url 'http://redmine.academ.org'
  description 'Adds ability to reorder wiki pages and show an ordered table of contents of Wiki'
  requires_redmine :version_or_higher => '2.0.0'
  url "http://redmine.academ.org"
  version '0.0.1'

  project_module :wiki_toc do
    permission :reorder_wiki_pages, { :wiki_toc => [:reorder] }
    permission :view_wiki_toc, { :wiki => [:table_of_contents] }, :read => true
  end

end

