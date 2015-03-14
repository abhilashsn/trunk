# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddBatchesIndexes < ActiveRecord::Migration
  def up
    add_index :batches, :status
  end

  def down
    remove_index :batches, :status
  end
end
