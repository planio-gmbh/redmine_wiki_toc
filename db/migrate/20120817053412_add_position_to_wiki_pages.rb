class AddPositionToWikiPages < ActiveRecord::Migration
  def self.up
    add_column :wiki_pages, :position, :integer, :null => false, :default => 1
    WikiPage.reset_column_information
    Wiki.transaction do
      Wiki.find_each do |wiki|
        wiki.pages.group_by(&:parent_id).each_value do |pages|
          pages.each_with_index { |page, idx| WikiPage.update_all("position=#{idx+1}", {:id => page.id}) }
        end
      end
    end
  end
  def self.down
    remove_column :wiki_pages, :position
  end
end
