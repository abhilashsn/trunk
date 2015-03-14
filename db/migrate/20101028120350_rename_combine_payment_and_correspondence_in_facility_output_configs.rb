class RenameCombinePaymentAndCorrespondenceInFacilityOutputConfigs < ActiveRecord::Migration
  def up
    rename_column :facility_output_configs, :combine_payment_and_correspondence, :separate_payment_and_correspondence
    rename_column :facility_output_configs, :combine_insurance_and_pat_pay, :separate_insurance_and_pat_pay
  end

  def down
    rename_column :facility_output_configs, :separate_payment_and_correspondence, :combine_payment_and_correspondence
    rename_column :facility_output_configs, :separate_insurance_and_pat_pay, :combine_insurance_and_pat_pay
  end
end
