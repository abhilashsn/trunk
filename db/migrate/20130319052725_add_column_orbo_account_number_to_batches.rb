class AddColumnOrboAccountNumberToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :orbo_account_number, :string, :limit => 50
  end
end
