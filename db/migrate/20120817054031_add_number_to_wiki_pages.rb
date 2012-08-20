class AddNumberToWikiPages < ActiveRecord::Migration
  def up
    add_column :wiki_pages, :number, :string, :null => false
    WikiPage.reset_column_information
    WikiPage.transaction do
      WikiPage.where(:parent_id => nil).each { |p| p.generate_number; p.save }
    end
  end
  def down
    remove_column :wiki_pages, :number
  end
end
