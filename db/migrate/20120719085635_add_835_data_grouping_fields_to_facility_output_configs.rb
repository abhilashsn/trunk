class Add835DataGroupingFieldsToFacilityOutputConfigs < ActiveRecord::Migration
  def change
    add_column :facility_output_configs, :payment_corres_patpay_in_one_file, :boolean, :default => false
    add_column :facility_output_configs, :payment_corres_in_one_patpay_in_separate_file, :boolean, :default => false
  end
end
