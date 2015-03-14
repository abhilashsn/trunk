# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddSessions < ActiveRecord::Migration
  def up
    create_table :sessions do |t|
      t.column :session_id, :string
      t.column :data, :text
      t.column :updated_at, :datetime
    end
    add_index :sessions, :session_id
  end

  def down
    drop_table :sessions
  end
end
