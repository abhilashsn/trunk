class CreateTableClaimLevelServiceLines < ActiveRecord::Migration
  def up
    create_table :claim_level_service_lines do |t|
      t.string :description, :null => false
      t.decimal :amount, :precision => 10, :scale => 2, :null => false
      t.integer :insurance_payment_eob_id, :null => false
      t.timestamps
    end
    add_index :claim_level_service_lines, :insurance_payment_eob_id, :name => 'by_insurance_payment_eob_id'
  end

  def down
    drop_table :claim_level_service_lines
  end
end
