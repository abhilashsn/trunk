# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddManualOverrideColumnToBatches < ActiveRecord::Migration
  def up
    add_column :batches, :manual_override, :boolean, :default => false
  end

  def down
    remove_column :batches, :manual_override
  end
end
