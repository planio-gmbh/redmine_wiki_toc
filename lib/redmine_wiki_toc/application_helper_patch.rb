module RedmineWikiToc
  module ApplicationHelperPatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :render_page_hierarchy, :number_prefix
      end
    end

    module InstanceMethods
      def render_page_hierarchy_with_number_prefix(*args)
        return render_page_hierarchy_without_number_prefix(*args) if WikiPage.number_prefix_disabled_tmp?
        WikiPage.with_disabled_number_prefix { render_page_hierarchy_without_number_prefix(*args) }
      end
    end
  end
end