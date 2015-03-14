class CreatePatientPayEobs < ActiveRecord::Migration
  def up
    create_table :patient_pay_eobs do |t|
      t.column :check_information_id, :integer,:references=>:check_informations
      t.column :practice_number, :string ,:limit =>30
      t.column :account_number, :string ,:limit =>30
      t.column :transaction_date, :date 
      t.column :stub_amount,:decimal,:precision => 10, :scale => 2
      t.column :check_amount,:decimal,:precision => 10, :scale => 2
      t.column :statement_amount,:decimal,:precision => 10, :scale => 2
      t.column :patient_last_name, :string ,:limit =>35
      t.column :patient_first_name, :string ,:limit =>35
      t.column :patient_middle_initial, :string ,:limit =>4
      t.column :patient_suffix, :string ,:limit =>3
      t.column :guarantor_last_name, :string ,:limit =>35
    end
    execute "ALTER TABLE patient_pay_eobs ADD CONSTRAINT patient_pay_eobs_idfk_1 FOREIGN KEY (check_information_id)
              REFERENCES check_informations(id)"
  end

  def down
    execute "ALTER TABLE patient_pay_eobs DROP FOREIGN KEY patient_pay_eobs_idfk_1"
    drop_table :patient_pay_eobs
  end
end
