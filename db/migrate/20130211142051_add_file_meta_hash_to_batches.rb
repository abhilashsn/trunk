class AddFileMetaHashToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :file_meta_hash, :string
  end
end
