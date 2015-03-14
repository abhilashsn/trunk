class AddColumnsToFacilities2 < ActiveRecord::Migration
  def up
    add_column :facilities, :client_dda_number,  :string
    add_column :facilities, :payer_ids_to_exclude,  :string
  end

  def down
    remove_column :facilities, :client_dda_number
    remove_column :facilities, :payer_ids_to_exclude
  end
end
