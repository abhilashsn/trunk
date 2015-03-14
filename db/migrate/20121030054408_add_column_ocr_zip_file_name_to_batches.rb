class AddColumnOcrZipFileNameToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :ocr_zip_file_name, :string
  end
end
