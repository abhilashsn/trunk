class ChangeDataTypesInTempJobs < ActiveRecord::Migration
  def up
    change_table :temp_jobs do |t|
      t.change :aba_number, :string, {:limit => 9}
      t.change :account_number, :string, {:limit => 15}
      t.change :check_number, :string, {:limit => 30}
    end
  end

  def down
    change_table :temp_jobs do |t|
      t.change :aba_number, :integer
      t.change :account_number, :integer
      t.change :check_number, :integer
    end
  end
end
