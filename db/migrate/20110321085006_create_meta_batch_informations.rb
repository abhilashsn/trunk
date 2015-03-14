class CreateMetaBatchInformations < ActiveRecord::Migration
  def up
    create_table :meta_batch_informations do |t|
      t.string :document_format
      t.datetime :due_time
      t.integer :priority
      t.string :provider_code
      t.integer :batch_id
      t.timestamps
    end
  end

  def down
    drop_table :meta_batch_informations
  end
end
