class AddColumnExistenceToReasonCodesJobs < ActiveRecord::Migration
  def up
    add_column :reason_codes_jobs, :existence, :boolean, :default => true
  end

  def down
    remove_column :reason_codes_jobs, :existence
  end
end
