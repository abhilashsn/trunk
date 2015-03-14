class CreateServicePaymentEobsAnsiRemarkCodes < ActiveRecord::Migration
  def up
    create_table :service_payment_eobs_ansi_remark_codes do |t|
      t.integer :service_payment_eob_id, :null => false
      t.integer :ansi_remark_code_id, :null => false

      t.timestamps
    end
  end

  def down
    drop_table :service_payment_eobs_ansi_remark_codes
  end
end
