class AddPayerIdsToIncludeToFacility < ActiveRecord::Migration
  def change
    add_column :facilities, :payer_ids_to_include, :string
  end
end
