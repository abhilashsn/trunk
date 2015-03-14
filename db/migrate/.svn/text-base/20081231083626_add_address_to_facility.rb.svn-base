class AddAddressToFacility < ActiveRecord::Migration
  def up
    add_column :facilities,:address_one,:string
    add_column :facilities,:address_two,:string
    add_column :facilities,:zip_code,:string
    add_column :facilities,:city,:string
    add_column :facilities,:state,:string
  end

  def down
    remove_column :facilities,:address_one,:string
    remove_column :facilities,:address_two,:string
    remove_column :facilities,:zip_code,:string
    remove_column :facilities,:city,:string
    remove_column  :facilities,:state,:string
  end
end
