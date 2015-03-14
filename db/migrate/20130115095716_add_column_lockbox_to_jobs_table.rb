class AddColumnLockboxToJobsTable < ActiveRecord::Migration
  def change
    add_column :jobs, :lockbox, :string, :limit=>20
  end
end
