class CreateCapitationAccounts < ActiveRecord::Migration
  def up
    create_table :capitation_accounts do |t|
      t.integer :account
      t.integer :payment
      t.integer :checknumber
      t.integer :batch_id
      t.integer :user_id
      t.string :payer_name      
      t.string :patient_first_name
      t.string :patient_last_name
      t.string :patient_initial
      t.string :patient_suffix
      t.timestamps
    end
  end

  def down
    drop_table :capitation_accounts
  end
end
