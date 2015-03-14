class RemoveOnbaseNameFromFacilitiesPayersInformations < ActiveRecord::Migration
  def up
        remove_column :facilities_payers_informations, :onbase_name
  end

  def down
      add_column :facilities_payers_informations, :onbase_name, :string
  end
end
