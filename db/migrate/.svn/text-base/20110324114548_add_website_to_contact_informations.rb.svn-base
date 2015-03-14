class AddWebsiteToContactInformations < ActiveRecord::Migration
  def up
    add_column :contact_informations, :website, :string, :limit => 200
  end

  def down
    remove_column :contact_informations, :website
  end
end
