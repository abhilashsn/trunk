class CreateTableInsurancePaymentEobsAnsiRemarkCodes < ActiveRecord::Migration
  def up
    create_table :insurance_payment_eobs_ansi_remark_codes do |t|
      t.integer :insurance_payment_eob_id, :null => false
      t.integer :ansi_remark_code_id, :null => false
      t.timestamps
    end
    add_index :insurance_payment_eobs_ansi_remark_codes, :insurance_payment_eob_id, :name => 'by_insurance_payment_eob_id'
    add_index :insurance_payment_eobs_ansi_remark_codes, :ansi_remark_code_id, :name => 'by_ansi_remark_code_id'
  end

  def down
    drop_table :insurance_payment_eobs_ansi_remark_codes
  end
end
