class CreateReconciliationInformations < ActiveRecord::Migration
  def up
    create_table :reconciliation_informations do |t|
      t.string :index_batch_number
      t.date :deposit_date
      t.string :lockbox_number
      t.boolean :is_batch_loaded, :default => false

      t.timestamps
    end
  end

  def down
    drop_table :reconciliation_informations
  end
end
