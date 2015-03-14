class AddAverageInsuranceEobProcessingProductivityAndAveragePatientPayEobProcessingProductivityToFacility < ActiveRecord::Migration
  def up
    add_column :facilities, :average_insurance_eob_processing_productivity, :decimal,:precision => 10, :scale => 6
    add_column :facilities, :average_patient_pay_eob_processing_productivity, :decimal,:precision => 10, :scale => 6
  end

  def down
    remove_column :facilities, :average_patient_pay_eob_processing_productivity
    remove_column :facilities, :average_insurance_eob_processing_productivity
  end
end
