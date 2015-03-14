class AddSourceToPayer < ActiveRecord::Migration
  def change
    add_column :payers, :source, :string
  end
end
