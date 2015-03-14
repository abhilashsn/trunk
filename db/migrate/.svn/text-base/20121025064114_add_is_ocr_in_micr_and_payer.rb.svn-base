class AddIsOcrInMicrAndPayer < ActiveRecord::Migration
  def up
    add_column :micr_line_informations, :is_ocr, :boolean, :default => false
  end

  def down
    remove_column :micr_line_informations, :is_ocr
  end
end
