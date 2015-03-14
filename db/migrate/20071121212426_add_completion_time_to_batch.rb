# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddCompletionTimeToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :completion_time, :datetime
  end

  def down
    remove_column :batches, :completion_time
  end
end
