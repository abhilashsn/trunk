# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddPayableToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :correspondence, :integer, :default => 0
  end
  def down
    remove_column :batches, :correspondence
  end
end
