class AddThird835DataGroupingColumnToFacilityOutputConfigs < ActiveRecord::Migration
  def change
    add_column :facility_output_configs, :payment_patpay_in_one_corres_in_separate_file, :boolean, :default => false
  end
end
