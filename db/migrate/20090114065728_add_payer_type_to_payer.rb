class AddPayerTypeToPayer < ActiveRecord::Migration
  def up
    add_column :payers,:payer_type, :string
  end

  def down
   remove_column :payers,:payer_type
  end
end
