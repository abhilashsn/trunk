# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddUpdatedByUpdatedAtCreatedByCreatedAtToJob < ActiveRecord::Migration
  def up
    add_column :jobs, :updated_by, :integer
    add_column :jobs, :updated_at, :datetime
    add_column :jobs, :created_by, :integer
    add_column :jobs, :created_at, :datetime
  end

  def down
    remove_column :jobs, :updated_by
    remove_column :jobs, :updated_at
    remove_column :jobs, :created_by
    remove_column :jobs, :created_at
  end
end
