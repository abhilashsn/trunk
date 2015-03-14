# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddAccuracyInEobReport < ActiveRecord::Migration
  def up
    add_column :eob_qas, :accuracy, :integer
    change_column :eob_reports, :account_number, :string
  end

  def down
    remove_column :eob_qas, :accuracy
    change_column :eob_reports, :account_number, :integer
  end
end
