# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class PredefinedJobComments < ActiveRecord::Migration
  def up
    comments = 
      [
      "Charge misplacement",
      "Did not change unwanted EOB to OTH",
      "Did not index co-insurance",
      "Did not index copay",
      "Did not index deductible",
      "Did not index denied amount",
      "Did not index HIC information",
      "Did not index interest payment",
      "Did not index non-covered charge",
      "Did not index paitent payment",
      "Did not index patients individually",
      "Did not index primary payer payment",
      "Did not index reason code",
      "Did not index service date",
      "Did not utilize MPI search",
      "First Name, last name flipped",
      "Incorrect allowed amount",
      "Incorrect charges",
      "Incorrect coinsurance",
      "Incorrect copay",
      "Incorrect default date",
      "Incorrect patient account number",
      "Incorrect patient name",
      "Incorrect patient payment",
      "Incorrect primary payer payment",
      "Incorrect service date",
      "Incorrectly indexed contractual adjustment amount into denied column",
      "Incorrectly indexed denied amount into non-covered column",
      "Incorrectly indexed multiple patients into one claim",
      "Incorrectly indexed non-covered amount into retention column",
      "Incorrectly indexed other insurance into copay column",
      "Incorrectly indexed primary payer payment amount in deductible column",
      "Index using only one line",
      "Line item error",
      "Unprocessed EOB",
    ]

    comments.each do |vl|
      execute "INSERT INTO job_rejection_comments(comment) VALUES('#{vl}')"
    end
    
  end

  def down
    JobRejectionComment.delete_all
  end
end
