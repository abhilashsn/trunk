class AddColumnDefaultBlankSegmentsToFacilities < ActiveRecord::Migration
  def change
    add_column :facilities, :patient_account_number_default_match, :string
    add_column :facilities, :patient_first_name_default_match, :string
    add_column :facilities, :patient_last_name_default_match, :string
    add_column :facilities, :cpt_code_default_match, :string
    add_column :facilities, :date_of_service_default_match, :date
  end
end
