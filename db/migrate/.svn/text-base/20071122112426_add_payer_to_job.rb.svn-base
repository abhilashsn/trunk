# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddPayerToJob < ActiveRecord::Migration
  def up
    add_column :jobs, :payer_id, :integer
    
  end

  def down
    
    remove_column :jobs, :payer_id
  end
end