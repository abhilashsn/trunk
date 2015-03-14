class AddColumnClientIdToFacilitiesMicrInformations < ActiveRecord::Migration
  def change
    add_column :facilities_micr_informations, :client_id, :integer
    add_index :facilities_micr_informations, :client_id, :name => 'by_client_id'    
  end
end
