class AddClientToPayer < ActiveRecord::Migration
  def up
     add_column :payers,:client,:string,:default=>'PEMA'
  end

  def down
    remove_column :payers,:client
  end
end
