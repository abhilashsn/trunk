class CreateColumnJobIdInPatientPayEobsTable < ActiveRecord::Migration
  def change
    add_column :patient_pay_eobs, :job_id, :integer
    add_index :patient_pay_eobs, :job_id
  end
end
