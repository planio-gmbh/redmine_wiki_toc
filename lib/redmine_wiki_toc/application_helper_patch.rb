module RedmineWikiToc
  module ApplicationHelperPatch
    extend ActiveSupport::Concern

    included do
      alias_method_chain :render_page_hierarchy, :number_prefix
    end

    def render_page_hierarchy_with_number_prefix(*args)
      return render_page_hierarchy_without_number_prefix(*args) if WikiPage.number_prefix_disabled_tmp?
      WikiPage.with_disabled_number_prefix { render_page_hierarchy_without_number_prefix(*args) }
    end
  end
end