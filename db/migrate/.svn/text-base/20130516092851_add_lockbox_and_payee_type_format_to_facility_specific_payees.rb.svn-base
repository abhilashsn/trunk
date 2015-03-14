class AddLockboxAndPayeeTypeFormatToFacilitySpecificPayees < ActiveRecord::Migration
  def change
    add_column :facility_specific_payees, :payee_type_format, :char, :limit => 1
    add_column :facility_specific_payees, :lockbox, :string, :limit => 20
  end
end
