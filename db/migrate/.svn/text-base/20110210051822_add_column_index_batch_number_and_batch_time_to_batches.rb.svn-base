class AddColumnIndexBatchNumberAndBatchTimeToBatches < ActiveRecord::Migration
  def up
    add_column :batches, :index_batch_number, :string
    add_column :batches, :batch_time, :datetime
  end

  def down
    remove_column :batches, :index_batch_number
    remove_column :batches, :batch_time
  end
end
