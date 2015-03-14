# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateQueryDetails < ActiveRecord::Migration
  def up
    create_table :query_details do |t|
      t.column :criteria, :string
      t.column :compare, :string
      t.column :from, :date
      t.column :to, :date
      t.column :created_at, :datetime
    end
  end

  def down
    drop_table :query_details
  end
end
