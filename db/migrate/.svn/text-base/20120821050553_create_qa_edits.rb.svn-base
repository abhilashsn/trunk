class CreateQaEdits < ActiveRecord::Migration
  def change
    create_table :qa_edits do |t|
      t.column :field_name, :string
      t.column :previous_value, :string
      t.column :current_value, :string
      t.references :insurance_payment_eob
      t.references :patient_pay_eob
      t.references :service_payment_eob
      t.references :user
      t.timestamps
    end
    add_index :qa_edits, :insurance_payment_eob_id
    add_index :qa_edits, :patient_pay_eob_id
    add_index :qa_edits, :service_payment_eob_id
    add_index :qa_edits, :user_id
  end
end
