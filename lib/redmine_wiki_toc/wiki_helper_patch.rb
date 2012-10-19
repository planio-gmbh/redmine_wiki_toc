module RedmineWikiToc
  module WikiHelperPatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :wiki_page_options_for_select, :ordering
        alias_method_chain :wiki_page_breadcrumb, :toc
      end
    end

    module InstanceMethods
      def wiki_page_options_for_select_with_ordering(*args)
        if @project && @project.module_enabled?(:wiki_toc)
          pages = args.first
          if pages.is_a?(Hash)
            pages.values.each { |a| a.sort! }
          else
            pages.sort!
          end
        end
        wiki_page_options_for_select_without_ordering(*args)
      end

      def wiki_page_breadcrumb_with_toc(page)
        links = page.ancestors.reverse.collect {|parent|
          link_to(h(parent.pretty_title), {:controller => 'wiki', :action => 'show', :id => parent.title, :project_id => parent.project})
        }
        if User.current.allowed_to?(:view_wiki_toc, page.project)
          links.unshift link_to(l(:label_table_of_contents), {:controller => 'wiki', :action => 'table_of_contents', :project_id => page.project})
        end
        breadcrumb(links)
      end
    end
  end
end