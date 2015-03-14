class AddColumnMismatchTransactionToCheckInformation < ActiveRecord::Migration
  def change
    add_column :check_informations, :mismatch_transaction, :boolean, :default => false
  end
end
