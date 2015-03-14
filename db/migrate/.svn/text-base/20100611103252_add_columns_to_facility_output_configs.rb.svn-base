class AddColumnsToFacilityOutputConfigs < ActiveRecord::Migration
  def up
    add_column :facility_output_configs, :report_type, :string, :limit => "50"
    add_column :facility_output_configs, :combine_insurance_and_pat_pay, :boolean, :default => false
  end

  def down
    remove_column :facility_output_configs, :report_type
    remove_column :facility_output_configs, :combine_insurance_and_pat_pay
  end
end
