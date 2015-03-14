# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddCommentToJob < ActiveRecord::Migration
  def up
    add_column :jobs, :comment, :string
  end

  def down
    remove_column :jobs, :comment
  end
end
