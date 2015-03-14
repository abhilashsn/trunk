class RemoveBankDepositDateFromBatches < ActiveRecord::Migration
  def up
    remove_column :batches, :bank_deposit_date
  end

  def down
    add_column :batches, :bank_deposit_date, :datetime
  end
end
