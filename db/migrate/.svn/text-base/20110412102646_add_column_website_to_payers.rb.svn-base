class AddColumnWebsiteToPayers < ActiveRecord::Migration
  def up
    add_column :payers, :website, :string, :limit => 200
  end

  def down
    remove_column :payers, :website
  end
end
