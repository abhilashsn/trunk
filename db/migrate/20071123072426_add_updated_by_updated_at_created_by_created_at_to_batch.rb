# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddUpdatedByUpdatedAtCreatedByCreatedAtToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :updated_by, :integer
    add_column :batches, :updated_at, :datetime
    add_column :batches, :created_by, :integer
    add_column :batches, :created_at, :datetime
  end

  def down
    remove_column :batches, :updated_by
    remove_column :batches, :updated_at
    remove_column :batches, :created_by
    remove_column :batches, :created_at
  end
end
