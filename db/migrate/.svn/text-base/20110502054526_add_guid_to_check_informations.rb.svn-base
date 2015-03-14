class AddGuidToCheckInformations < ActiveRecord::Migration
  def up
    add_column :check_informations, :guid, :string, :limit => 36
  end

  def down
    remove_column :check_informations, :guid
  end
end
