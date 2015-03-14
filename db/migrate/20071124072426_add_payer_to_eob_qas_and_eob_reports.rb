# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddPayerToEobQasAndEobReports < ActiveRecord::Migration
  def up
    add_column :eob_qas, :payer, :string 
    add_column :eob_reports, :payer, :string
  end

  def down
    remove_column :eob_qas, :payer
    remove_column :eob_reports, :payer    
  end
end