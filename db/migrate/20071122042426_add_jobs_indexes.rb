# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddJobsIndexes < ActiveRecord::Migration
  def up
    add_index :jobs, :batch_id
    add_index :jobs, :processor_id
    add_index :jobs, :qa_id
  end

  def down
    remove_index :jobs, :batch_id
    remove_index :jobs, :processor_id
    remove_index :jobs, :qa_id
  end
end
