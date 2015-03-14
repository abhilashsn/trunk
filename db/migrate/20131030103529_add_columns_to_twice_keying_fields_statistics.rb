class AddColumnsToTwiceKeyingFieldsStatistics < ActiveRecord::Migration
  def change
    add_column :twice_keying_fields_statistics, :payer_id, :integer
    add_column :twice_keying_fields_statistics, :check_information_id, :integer
    add_column :twice_keying_fields_statistics, :insurance_payment_eob_id, :integer
  end
end
