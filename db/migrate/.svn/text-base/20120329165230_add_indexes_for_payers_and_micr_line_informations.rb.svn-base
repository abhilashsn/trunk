class AddIndexesForPayersAndMicrLineInformations < ActiveRecord::Migration
  def change
    add_index :payers, :payer
    add_index :payers, :payid
    add_index :micr_line_informations, :payid_temp
  end
end
