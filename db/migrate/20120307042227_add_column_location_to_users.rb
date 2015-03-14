class AddColumnLocationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :location, :string, :limit => 50
  end
end
