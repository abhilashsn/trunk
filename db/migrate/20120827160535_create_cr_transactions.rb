class CreateCrTransactions < ActiveRecord::Migration
  def change
    create_table :cr_transactions do |t|
      t.string :eft_trace_number_ed
      t.string :eft_trace_number_eda
      t.string :eft_date
      t.string :eft_payment_amount
      t.string :payment_format_code
      t.string :receivers_name
      t.string :payer_name
      t.string :batch_number
      t.integer :ach_file_id
      t.string :status
      t.integer :aba_dda_lookup_id
      t.string :company_id

      t.timestamps
    end
  end
end
