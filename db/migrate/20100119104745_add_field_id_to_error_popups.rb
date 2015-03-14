class AddFieldIdToErrorPopups < ActiveRecord::Migration
  def up
    add_column :error_popups, :field_id,  :string
  end

  def down
    remove_column :error_popups, :field_id
  end
end
