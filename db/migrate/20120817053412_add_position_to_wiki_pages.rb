class AddPositionToWikiPages < ActiveRecord::Migration
  def up
    add_column :wiki_pages, :position, :integer, :null => false, :default => 1
    WikiPage.reset_column_information
    Wiki.transaction do
      Wiki.find_each do |wiki|
        wiki.pages.group_by(&:parent_id).each_value do |pages|
          pages.each_with_index { |page, idx| page.update_column(:position, idx+1) }
        end
      end
    end
  end
  def down
    remove_column :wiki_pages, :position
  end
end
