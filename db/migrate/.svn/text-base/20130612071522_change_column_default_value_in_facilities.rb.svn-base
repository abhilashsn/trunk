class ChangeColumnDefaultValueInFacilities < ActiveRecord::Migration
  def up
    change_column :facilities, :ocr_enabled_flag, :boolean, :default => false, :null => false
  end

  def down
    change_column :facilities, :ocr_enabled_flag, :boolean, :default => nil, :null => true
  end
end
