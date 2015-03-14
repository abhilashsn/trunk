# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateDocuments < ActiveRecord::Migration
  def up
    create_table :documents do |t|
      t.column :filename, :string
      t.column :content, :binary
    end
  end

  def down
    drop_table :documents
  end
end
