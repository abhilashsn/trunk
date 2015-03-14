class ChangeTypeOfCutNumberInBatches < ActiveRecord::Migration
  def up
    change_column :batches, :cut_number, :string, :limit => 1
    rename_column :batches, :cut_number, :cut
  end

  def down
    change_column :batches, :cut_number, :integer, :limit => 11
    rename_column :batches, :cut, :cut_number
  end
end
