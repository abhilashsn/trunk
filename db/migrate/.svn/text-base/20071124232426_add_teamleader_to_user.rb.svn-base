# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddTeamleaderToUser < ActiveRecord::Migration
  def up
    add_column :users, :teamleader_id, :integer
  end

  def down
    remove_column :users, :teamleader_id
  end
end
