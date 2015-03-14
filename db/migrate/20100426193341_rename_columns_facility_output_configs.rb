class RenameColumnsFacilityOutputConfigs < ActiveRecord::Migration
  def up
    rename_column :facility_output_configs, :combine_pay_corr, :combine_payment_and_correspondence
    rename_column :facility_output_configs, :multi_transac, :multi_transaction
    rename_column :facility_output_configs, :group, :grouping
    rename_column :facility_output_configs, :file_name_components, :file_name
  end

  def down
    rename_column :facility_output_configs, :combine_payment_and_correspondence, :combine_pay_corr
    rename_column :facility_output_configs, :multi_transaction, :multi_transac
    rename_column :facility_output_configs, :grouping, :group
    rename_column :facility_output_configs, :file_name, :file_name_components
  end
end
