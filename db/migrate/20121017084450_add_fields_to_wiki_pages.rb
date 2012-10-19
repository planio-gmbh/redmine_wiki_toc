class AddFieldsToWikiPages < ActiveRecord::Migration
  def self.up
    change_table :wiki_pages do |t|
      t.boolean :number_enabled, :null => false, :default => true
      t.integer :number_delta, :null => false, :default => 0
    end
  end
  def self.down
    change_table :wiki_pages do |t|
      t.remove :number_delta
      t.remove :number_enabled
    end
  end
end
