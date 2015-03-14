# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AlterStatusToProcessorStatusInJob < ActiveRecord::Migration
  def up
    rename_column :jobs, :status, :processor_status
  end

  def down
    rename_column :jobs, :processor_status, :status
  end
end
