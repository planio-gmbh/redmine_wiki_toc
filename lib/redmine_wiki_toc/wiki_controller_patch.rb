module RedmineWikiToc
  module WikiControllerPatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def table_of_contents
        @pages = @wiki.pages.with_updated_on.find(:all, :include => {:wiki => {:project => :enabled_modules}})
        @pages = @pages.sort.group_by(&:parent_id)
      end
    end
  end
end