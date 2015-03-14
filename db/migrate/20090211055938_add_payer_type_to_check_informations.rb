class AddPayerTypeToCheckInformations < ActiveRecord::Migration
  def up
    add_column :check_informations,:payer_type, :string
  end

  def down
    remove_column :check_informations,:payer_type
  end
end
