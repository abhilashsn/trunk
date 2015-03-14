class AddFileNameAndCutNumberToBatches < ActiveRecord::Migration
  def up
    add_column :batches, :file_name, :string
    add_column :batches, :cut_number, :integer
  end

  def down
    remove_column :batches, :file_name
    remove_column :batches, :cut_number
  end
end
