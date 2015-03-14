# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddContractedTatToClient < ActiveRecord::Migration
  def up
    add_column :clients, :contracted_tat, :integer
  end

  def down
    remove_column :clients, :contracted_tat
  end
end
