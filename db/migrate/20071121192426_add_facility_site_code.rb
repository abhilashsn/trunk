# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddFacilitySiteCode < ActiveRecord::Migration
  def up
    add_column :facilities, :sitecode, :string
  end

  def down
    remove_column :facilities, :sitecode
  end
end
