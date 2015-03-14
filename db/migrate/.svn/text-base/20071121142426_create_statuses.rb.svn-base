# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateStatuses < ActiveRecord::Migration
  def up
    create_table :statuses do |t|
      t.column :value, :string
    end
  end

  def down
    drop_table :statuses
  end
end
