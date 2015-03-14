class ChangeDefaultOf835DataGroupingFields < ActiveRecord::Migration
  def up
    change_column :facility_output_configs, :payment_corres_in_one_patpay_in_separate_file, :boolean, :default => true
  end

  def down
    change_column :facility_output_configs, :payment_corres_in_one_patpay_in_separate_file, :boolean, :default => false
  end
end
