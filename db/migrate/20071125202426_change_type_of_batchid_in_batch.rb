class ChangeTypeOfBatchidInBatch < ActiveRecord::Migration
  def up
    change_column :batches, :batchid ,:string
  end

  def down
    change_column :batches, :batchid ,:integer 
  end
end
