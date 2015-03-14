class AddColumnSsiBatchNumberToBatches < ActiveRecord::Migration
  def change
     add_column :batches, :ssi_batch_number, :string
  end
end
