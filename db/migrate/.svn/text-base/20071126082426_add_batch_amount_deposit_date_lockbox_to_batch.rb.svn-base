class AddBatchAmountDepositDateLockboxToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :batch_amount, :decimal,:precision => 10, :scale => 2
    add_column :batches, :bank_deposit_date, :date
    add_column :batches, :lockbox,:string,:limit =>20
    add_column :batches, :bank_deposit_id_number,:string,:limit =>20
    add_column :batches, :client_id,:string,:limit =>20
  end

  def down
    remove_column :batches, :batch_amount
    remove_column :batches, :bank_deposit_date
    remove_column :batches, :lockbox
    remove_column :batches, :bank_deposit_id_number
    remove_column :batches, :client_id
  end
end
