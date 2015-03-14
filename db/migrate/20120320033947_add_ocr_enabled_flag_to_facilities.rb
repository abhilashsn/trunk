class AddOcrEnabledFlagToFacilities < ActiveRecord::Migration
  def change
     add_column :facilities, :ocr_enabled_flag, :boolean
  end
end
