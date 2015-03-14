class AddColumnSupplementalOutputsToClients < ActiveRecord::Migration
  def change
    add_column :clients, :supplemental_outputs, :string
  end
end
