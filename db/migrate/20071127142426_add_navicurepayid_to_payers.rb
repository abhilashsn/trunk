class AddNavicurepayidToPayers < ActiveRecord::Migration
  def up
    add_column :payers,:navicurepayid,:string
  end

  def down
    remove_column :payers,:navicurepayid
  end
end
