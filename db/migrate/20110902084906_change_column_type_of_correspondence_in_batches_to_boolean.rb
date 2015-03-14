class ChangeColumnTypeOfCorrespondenceInBatchesToBoolean < ActiveRecord::Migration
  def up
    change_column :batches,:correspondence,:boolean,:default => false
  end

  def down
    change_column :batches,:correspondence,:integer, :default => 0
  end
end
