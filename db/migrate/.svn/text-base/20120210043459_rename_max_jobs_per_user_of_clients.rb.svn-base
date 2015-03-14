class RenameMaxJobsPerUserOfClients < ActiveRecord::Migration
  def up
    rename_column :clients, :max_jobs_per_user, :max_jobs_per_user_client_wise
  end

  def down
    rename_column :clients, :max_jobs_per_user_client_wise, :max_jobs_per_user
  end
end
