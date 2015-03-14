class AddIndexPayerIdAndFacilityIdInFacilitiesMicrInformations < ActiveRecord::Migration
  def change
    add_index :facilities_payers_informations, :facility_id
    add_index :facilities_payers_informations, :payer_id
    
  end
end
