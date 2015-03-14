class AddTransactionNumberToJobs < ActiveRecord::Migration
  def up
     add_column :jobs, :transaction_number, :string
  end

  def down
    remove_column :jobs, :transaction_number
  end
end
