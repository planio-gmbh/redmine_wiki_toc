module RedmineWikiToc
  module WikiControllerPatch
    extend ActiveSupport::Concern

    def table_of_contents
      @pages = @wiki.pages.with_updated_on.includes(:wiki => {:project => :enabled_modules}).reorder(:position)
      @pages = @pages.group_by(&:parent_id)
    end
  end
end