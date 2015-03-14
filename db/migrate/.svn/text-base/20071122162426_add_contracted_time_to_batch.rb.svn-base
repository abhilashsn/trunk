# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddContractedTimeToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :contracted_time, :datetime
  end

  def down
    remove_column :batches, :contracted_time
  end
end
