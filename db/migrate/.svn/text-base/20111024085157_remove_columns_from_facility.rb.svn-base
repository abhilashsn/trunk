class RemoveColumnsFromFacility < ActiveRecord::Migration
  def up
    remove_column :facilities, :payer_ids_to_include
    remove_column :facilities, :payer_ids_to_exclude
  end

  def down
    add_column :facilities, :payer_ids_to_exclude, :string
    add_column :facilities, :payer_ids_to_include, :string
  end
end
