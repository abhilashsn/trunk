class CreateEobReasonCodes < ActiveRecord::Migration
  def change
    create_table :eob_reason_codes do |t|
      t.column :page_no, :integer
      t.column :insurance_payment_eob_id, :integer
      t.column :reason_code_id, :integer
      t.column :job_id, :integer
      t.timestamps
    end
  end
end
