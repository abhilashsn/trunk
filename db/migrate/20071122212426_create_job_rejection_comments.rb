# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateJobRejectionComments < ActiveRecord::Migration
  def up
    create_table :job_rejection_comments do |t|
      t.column :comment, :string
    end
  end

  def down
    drop_table :job_rejection_comments
  end
end
