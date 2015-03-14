# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddJobStatusAndQaStatusToJob < ActiveRecord::Migration
  def up
    add_column :jobs, :job_status, :string, :default => JobStatus::NEW
    add_column :jobs, :qa_status, :string, :default => QaStatus::NEW
  end

  def down
    remove_column :jobs, :job_status
    remove_column :jobs, :qa_status
  end
end
