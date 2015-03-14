class AddEnableCrToFacilities < ActiveRecord::Migration
  def change
    add_column :facilities, :enable_cr, :boolean
  end
end
