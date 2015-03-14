# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateEobErrors < ActiveRecord::Migration
  def up
    create_table :eob_errors do |t|
      t.column :error_type, :string
      t.column :severity, :integer
      t.column :code, :string
      t.column :eob_qa_id, :integer
    end
  end

  def down
    drop_table :eob_errors
  end
end
