class AddPayeeNpiToFacilitySpecificPayees < ActiveRecord::Migration
  def change
     add_column :facility_specific_payees, :payee_npi, :string
  end
end
