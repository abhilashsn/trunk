class AddSupplementalOutputsToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :supplemental_outputs, :string
  end

  def down
    remove_column :facilities, :supplemental_outputs
  end
end
