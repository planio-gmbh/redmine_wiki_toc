module RedmineWikiToc
  module Helper
    def include_wiki_toc_assets
      unless @wiki_toc_assets_included
        @wiki_toc_assets_included = true
        content_for :header_tags do
          stylesheet_link_tag('wiki_toc', :plugin => 'redmine_wiki_toc')
        end
      end
    end
    def render_wiki_toc(pages, node=nil, options={}, depth = nil)
      include_wiki_toc_assets
      content = ''
      highlight = options[:highlight]
      parent = options[:parent] && options[:parent].visible? && options.delete(:parent)
      reorder = options[:reorder_links] && User.current.allowed_to?(:reorder_wiki_pages, options[:project] || @project)
      node_id = node.try(:id)
      unless depth
        content << "<div class='wiki-toc #{"reorder" if reorder}'>"
        if parent
          content << "<ul class='pages-hierarchy'>"
          content << "<li><span class='number'>" + parent.numeric_prefix + "</span>"
          content << link_to(h(parent.pretty_title_without_number), {:controller => 'wiki', :action => 'show', :project_id => parent.project, :id => parent.title},
                             :title => (options[:timestamp] && parent.updated_on ? l(:label_updated_time, distance_of_time_in_words(Time.now, parent.updated_on)) : nil))
        end
      end
      if pages[node_id]
        _depth = depth || 0
        _depth_remains = options[:depth] && (options[:depth] - _depth)
        content << "<ul class='pages-hierarchy #{node_id && "node-#{node_id}" || "root"}'>"
        pages[node_id].select {|page| page.visible?}.each do |page|
          content << "<li class='item-#{page.id}'>"
          content << "<span class='reorder-links'>" + reorder_links_remote('page', {:controller => 'wiki_toc', :action => 'reorder', :project_id => page.project, :id => page.title, :depth => _depth_remains}) + "</span>" if reorder
          content << "<span class='number'>" + page.numeric_prefix + "</span>"
          content << link_to(h(page.pretty_title_without_number), {:controller => 'wiki', :action => 'show', :project_id => page.project, :id => page.title},
                             :class => highlight == page ? "current" : "",
                             :title => (options[:timestamp] && page.updated_on ? l(:label_updated_time, distance_of_time_in_words(Time.now, page.updated_on)) : nil))
          content << render_wiki_toc(pages, page, options, _depth+1) if pages[page.id] && (!options[:depth] || _depth < options[:depth])
          content << "</li>"
        end
        content << "</ul>"
      end
      unless depth
        content << "</li></ul>" if parent
        content << "</div>"
      end
      content.html_safe
    end
    if Redmine::VERSION::MAJOR >= 2
      def reorder_links_remote(name, url, method = :post)
        link_to(image_tag('2uparrow.png', :alt => l(:label_sort_highest)),
                url.merge({"#{name}[move_to]" => 'highest'}),
                :method => method, :title => l(:label_sort_highest), :remote => true) +
        link_to(image_tag('1uparrow.png', :alt => l(:label_sort_higher)),
                url.merge({"#{name}[move_to]" => 'higher'}),
               :method => method, :title => l(:label_sort_higher), :remote => true) +
        link_to(image_tag('1downarrow.png', :alt => l(:label_sort_lower)),
                url.merge({"#{name}[move_to]" => 'lower'}),
                :method => method, :title => l(:label_sort_lower), :remote => true) +
        link_to(image_tag('2downarrow.png', :alt => l(:label_sort_lowest)),
                url.merge({"#{name}[move_to]" => 'lowest'}),
               :method => method, :title => l(:label_sort_lowest), :remote => true)
      end
    else
      def reorder_links_remote(name, url, method = :post)
        link_to_remote(image_tag('2uparrow.png', :alt => l(:label_sort_highest)),
                {:url => url.merge({"#{name}[move_to]" => 'highest'}), :method => method},
                :title => l(:label_sort_highest)) +
        link_to_remote(image_tag('1uparrow.png', :alt => l(:label_sort_higher)),
                {:url => url.merge({"#{name}[move_to]" => 'higher'}), :method => method},
                :title => l(:label_sort_higher)) +
        link_to_remote(image_tag('1downarrow.png', :alt => l(:label_sort_lower)),
                {:url => url.merge({"#{name}[move_to]" => 'lower'}), :method => method},
                :title => l(:label_sort_lower)) +
        link_to_remote(image_tag('2downarrow.png', :alt => l(:label_sort_lowest)),
                {:url => url.merge({"#{name}[move_to]" => 'lowest'}), :method => method},
                :title => l(:label_sort_lowest))
      end
    end
  end
end