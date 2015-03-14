# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateBatchRejectionComments < ActiveRecord::Migration
  def up
    create_table :batch_rejection_comments do |t|
      t.column :comment, :string
    end
  end

  def down
    drop_table :batch_rejection_comments
  end
end
