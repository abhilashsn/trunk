# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddBatchIssueAttributes < ActiveRecord::Migration
  def up
    add_column :batches, :system_issue, :integer, :default => 0
    add_column :batches, :policy_issue, :integer, :default => 0
  end

  def down
    remove_column :batches, :system_issue
    remove_column :batches, :policy_issue
  end
end
