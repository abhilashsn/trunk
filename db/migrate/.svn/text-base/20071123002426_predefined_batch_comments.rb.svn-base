# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class PredefinedBatchComments < ActiveRecord::Migration
  def up
    comments=[
      "Did not change unwanted EOB to OTH",
      "Incorrect default date",
      "Incorrectly indexed partial date",
      "Incorrect retention amount"
    ]
    comments.each do |vl|
      execute "INSERT INTO batch_rejection_comments(comment) VALUES('#{vl}')"
    end
  end

  def down
    #BatchRejectionComment.delete_all
  end
end
