class AddZipcodeStateCityToPayer < ActiveRecord::Migration
  def up
     add_column :payers,:payer_zip,:string
     add_column :payers,:payer_state,:string
     add_column :payers,:payer_city,:string
  end

  def down
    remove_column :facilities,:payer_zip
    remove_column :facilities,:payer_state
    remove_column :facilities,:payer_city
  end
end
