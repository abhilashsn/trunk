class AddCreatedAtUpdatedAtToPatientPayEobs < ActiveRecord::Migration
  def up
   add_column :patient_pay_eobs, :created_at, :datetime
   add_column :patient_pay_eobs, :updated_at, :datetime
  end

  def down
     remove_column :patient_pay_eobs, :created_at
     remove_column :patient_pay_eobs, :updated_at
  end
end
