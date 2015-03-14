class CreateTableBatchUploadParser < ActiveRecord::Migration
  def change
    create_table :batch_upload_parsers do |t|
      t.string :name
      t.string :class_name
    end
  end
end
