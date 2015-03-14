# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddIndexes < ActiveRecord::Migration
  def up
    add_index :batches, :batchid
    add_index :jobs, :processor_status
    add_index :jobs, :qa_status
    add_index :eob_reports, :qa
    add_index :eob_reports, :processor
  end

  def down
    remove_index :batches, :batchid
    remove_index :jobs, :processor_status
    remove_index :jobs, :qa_status
    remove_index :eob_reports, :qa
    remove_index :eob_reports, :processor
  end
end
