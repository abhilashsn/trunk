class AddIsDeletedToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :is_deleted, :boolean, :default => false
  end

  def down
    remove_column :facilities, :is_deleted
  end
end
