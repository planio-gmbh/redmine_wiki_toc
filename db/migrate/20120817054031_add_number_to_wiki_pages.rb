class AddNumberToWikiPages < ActiveRecord::Migration
  def self.up
    add_column :wiki_pages, :number, :string, :null => false, :default => ""
    WikiPage.reset_column_information
    WikiPage.transaction do
      WikiPage.find(:all, :conditions => {:parent_id => nil}).each { |p| p.assign_number; p.save }
    end
  end
  def self.down
    remove_column :wiki_pages, :number
  end
end
