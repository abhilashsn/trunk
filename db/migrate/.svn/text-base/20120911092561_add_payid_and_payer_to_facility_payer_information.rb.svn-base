class AddPayidAndPayerToFacilityPayerInformation < ActiveRecord::Migration
    def up
     add_column :facilities_payers_informations, :payid, :string
     add_column :facilities_payers_informations, :payer, :string
     add_column :facilities_payers_informations, :client_id, :int
   end
	def down
     remove_column :facilities_payers_informations, :payid
     remove_column :facilities_payers_informations, :payer
     remove_column :facilities_payers_informations, :client_id
  end
end
