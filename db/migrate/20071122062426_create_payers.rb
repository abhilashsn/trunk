# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreatePayers < ActiveRecord::Migration
  def up
    create_table :payers do |t|
      t.column :date_added, :date
      t.column :initials, :string
      t.column :from, :string
      t.column :gateway, :string
      t.column :payid, :string
      t.column :payer, :string
      t.column :gr_name, :string
      t.column :pay_address_one, :text
      t.column :pay_address_two, :text
      t.column :pay_address_three, :text
      t.column :pay_address_four, :text
      t.column :phone, :string
      t.column :deleted_at,  :datetime
      t.column :details, :text
    end
  end

  def down
    drop_table :payers
  end
end
