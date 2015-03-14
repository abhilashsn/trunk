class AddColumnsToMpiTables < ActiveRecord::Migration
  def up
    attributes = ["claim_frequency_type_code","iplan","supplemental_iplan","legacy_provider_number","claim_statement_period_start_date","claim_statement_period_end_date","carrier_code","claim_number","business_unit_indicator"]
    if !(attributes - ClaimInformation.column_names).empty?
      add_column :claim_informations, :iplan, :string
      add_column :claim_informations, :supplemental_iplan, :string
      add_column :claim_informations, :legacy_provider_number, :string
      add_column :claim_informations, :claim_statement_period_start_date, :date
      add_column :claim_informations, :claim_statement_period_end_date, :date
      add_column :claim_informations, :carrier_code, :string
      add_column :claim_informations, :claim_number, :string
      add_column :claim_informations, :business_unit_indicator, :integer
    end
  end

  def down
    remove_column :claim_informations, :iplan
    remove_column :claim_informations, :supplemental_iplan
    remove_column :claim_informations, :legacy_provider_number
    remove_column :claim_informations, :claim_statement_period_start_date
    remove_column :claim_informations, :claim_statement_period_end_date
    remove_column :claim_informations, :carrier_code
    remove_column :claim_informations, :claim_number
    remove_column :claim_informations, :business_unit_indicator
  end
  def connection
    ClaimInformation.connection
  end
  def connection
    ClaimServiceInformation.connection
  end
end
