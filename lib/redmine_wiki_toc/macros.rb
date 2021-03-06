module RedmineWikiIndex
  module Macros
    Redmine::WikiFormatting::Macros.register do
      desc "Displays a table of contents of Wiki. With no argument, it displays the child pages of the current wiki page. Examples:\n\n" +
             "  !{{wiki_toc}} -- can be used from a wiki page only\n" +
             "  !{{wiki_toc(Foo)}} -- lists all children of page Foo\n" +
             "  !{{wiki_toc(Foo, parent=1)}} -- shows a higher level of page hierarchy including Foo and all Foo's children\n" +
             "  !{{wiki_toc(Foo, depth=1)}} -- lists all children of page Foo down to specified depth\n" +
             "  !{{wiki_toc(reorder=1)}} -- shows reorder links\n" +
             "  !{{wiki_toc(highlight=1)}} -- highlight current or specified page\n" +
             "  !{{wiki_toc(header=Table of contents)}} -- shows header with a link to the table of contents\n" +
             "  !{{wiki_toc(root=1)}} -- shows entire page hierarchy from root"
      macro :wiki_toc do |obj, args|
        args, options = extract_macro_options(args, :parent, :depth, :root, :header, :reorder, :highlight)
        page = nil
        if args.size > 0
          page = Wiki.find_page(args.first.to_s, :project => @project)
          raise 'Page not found' if page.nil? || !page.visible?
        elsif obj.respond_to?(:page)
          page = obj.page == obj.page.wiki.sidebar ? @page : obj.page
        end
        wiki = page && page.wiki || @project && @project.wiki
        project = page && page.project || @project
        start_page = nil
        return unless project && project.module_enabled?(:wiki_toc)
        return "" unless User.current.allowed_to?(:view_wiki_toc, project)
        if !page || options[:root]
          pages = wiki.pages.find(:all)
        else
          if options[:parent] && !page.parent_id
            pages = wiki.pages.find(:all, :conditions => {:parent_id => nil})
          else
            start_page = options[:parent] ? page.parent : page
            pages = [start_page] + start_page.children
          end
          pages += page.descendants if page
          pages.uniq!
        end
        pages.sort!
        pages = pages.group_by(&:parent_id)
        return "" unless pages[start_page.try(:id)]
        options.merge! :depth => options[:depth] && options[:depth].to_i,
          :highlight => options[:highlight] && page,
          :parent => options[:parent] && page && page.parent,
          :reorder_links => options[:reorder].present?,
          :project => project
        content = "".html_safe
        if options[:header]
          header = options[:header]
          header = link_to(header, {:controller => 'wiki', :action => 'table_of_contents', :project_id => project}) if User.current.allowed_to?(:view_wiki_toc, project)
          content << content_tag('h3', header)
        end
        content << render_wiki_toc(pages, start_page, options)
      end
      desc "Displays a link to the table of contents. Examples:\n\n" +
           "  !{{toc_link(Table of contents)}}"
      macro :toc_link do |obj, args|
        return unless obj.respond_to? :project
        project = obj.project
        return unless project.module_enabled?(:wiki_toc)
        return "" unless User.current.allowed_to?(:view_wiki_toc, project)
        link_to(args.first || l(:label_table_of_contents), {:controller => 'wiki', :action => 'table_of_contents', :project_id => project})
      end
      desc "Displays a title of the current wiki page"
      macro :title do |obj, args|
        return unless obj.is_a?(WikiContent) || obj.is_a?(WikiContent::Version)
        obj.page.pretty_title
      end
    end
  end
end