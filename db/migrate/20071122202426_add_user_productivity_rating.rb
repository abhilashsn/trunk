# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddUserProductivityRating < ActiveRecord::Migration
  def up
    add_column :users, :rating, :string 
  end

  def down
    remove_column :users, :rating
  end
end
