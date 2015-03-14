class AddUidToPatPayEobs < ActiveRecord::Migration
  def change
    add_column :patient_pay_eobs, :uid, :integer
  end
end
