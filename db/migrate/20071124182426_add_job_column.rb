# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddJobColumn < ActiveRecord::Migration
  def up
    add_column :jobs, :rejections, :integer, :default => 0
  end

  def down
    remove_column :jobs, :rejections
  end
end
