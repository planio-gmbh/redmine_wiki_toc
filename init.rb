require 'redmine'
require 'redmine_wiki_toc/macros'
require 'redmine_wiki_toc/hooks'

to_prepare = Proc.new do
  unless WikiPage.include?(RedmineWikiToc::WikiPagePatch)
    WikiPage.send :include, RedmineWikiToc::WikiPagePatch
  end
  unless ActionView::Base.include?(RedmineWikiToc::Helper)
    ActionView::Base.send :include, RedmineWikiToc::Helper
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

if Redmine::VERSION::MAJOR >= 2
  Rails.configuration.to_prepare(&to_prepare)
else
  require 'dispatcher'
  Dispatcher.to_prepare(:redmine_wiki_toc, &to_prepare)
end

Redmine::Plugin.register :redmine_wiki_toc do
  name 'Redmine Wiki table of contents plugin'
  author 'Anton Argirov'
  author_url 'http://redmine.academ.org'
  description 'Adds ability to reorder wiki pages and show an ordered table of contents of Wiki'
  url "http://redmine.academ.org"
  version '0.0.3'

  project_module :wiki_toc do
    permission :reorder_wiki_pages, { :wiki_toc => [:reorder] }
    permission :view_wiki_toc, { :wiki => [:table_of_contents] }, :read => true
  end
end

