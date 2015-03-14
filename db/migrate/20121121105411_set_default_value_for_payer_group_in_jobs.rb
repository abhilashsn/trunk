class SetDefaultValueForPayerGroupInJobs < ActiveRecord::Migration
  def up
    change_column :jobs, :payer_group, :string, :limit => 15,:default => "--", :null => false
  end

  def down
    change_column :jobs, :payer_group, :string, :limit => 15
  end
end
