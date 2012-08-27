class ChangeWikiPagesColumns < ActiveRecord::Migration
  def self.up
    change_column :wiki_pages, :position, :integer, :null => true, :default => 1
    change_column :wiki_pages, :number, :string, :null => true
  end

  def self.down
    change_column :wiki_pages, :position, :integer, :null => false, :default => 1
    change_column :wiki_pages, :number, :string, :null => false
  end
end
