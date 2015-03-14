# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateRunner < ActiveRecord::Migration
  def up
    create_table :runners do |t|
      t.column :imported_at, :datetime
      t.column :imported_by, :string
      t.column :imported_from, :string
    end
  end

  def down
    drop_table :runners
  end
end
