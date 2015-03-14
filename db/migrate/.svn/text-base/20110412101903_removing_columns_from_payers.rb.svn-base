class RemovingColumnsFromPayers < ActiveRecord::Migration
  def up
    remove_column :payers, :from
    remove_column :payers, :initials
    remove_column :payers, :pay_address_four
  end

  def down
    add_column :payers, :from, :string
    add_column :payers, :initials, :string
    add_column :payers, :pay_address_four, :text
  end
end
