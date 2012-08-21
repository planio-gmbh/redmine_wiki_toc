module RedmineWikiToc
  module WikiHelperPatch
    extend ActiveSupport::Concern

    included do
      alias_method_chain :wiki_page_options_for_select, :ordering
    end

    def wiki_page_options_for_select_with_ordering(*args)
      if @project && @project.module_enabled?(:wiki_toc)
        pages = args.first
        if pages.is_a?(Hash)
          pages.values.each { |a| a.sort_by! {|p| p.position} }
        else
          pages.sort_by! {|p| p.position}
        end
      end
      wiki_page_options_for_select_without_ordering(*args)
    end
  end
end