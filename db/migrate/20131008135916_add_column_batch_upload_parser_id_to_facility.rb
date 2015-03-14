class AddColumnBatchUploadParserIdToFacility < ActiveRecord::Migration
  def change
    add_column :facilities, :batch_upload_parser_id, :integer
  end
end
