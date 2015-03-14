class AddTransactionIdToCheckInformations < ActiveRecord::Migration
  def change
    add_column :check_informations, :transaction_id, :string, :limit => 64
  end
end
