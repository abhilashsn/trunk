# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddDefaultContractedTat < ActiveRecord::Migration
  def up
    change_column :clients, :contracted_tat, :integer, :default => 20
  end

  def down
    change_column :clients, :contracted_tat, :integer
  end
end
