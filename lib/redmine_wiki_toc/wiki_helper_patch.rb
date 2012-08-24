module RedmineWikiToc
  module WikiHelperPatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :wiki_page_options_for_select, :ordering
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
    end
  end
end