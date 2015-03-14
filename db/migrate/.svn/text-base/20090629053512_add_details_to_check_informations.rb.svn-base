class AddDetailsToCheckInformations < ActiveRecord::Migration
  def up
    begin
    add_column :check_informations, :details, :text
    rescue
    end
  end

  def down
    remove_column :check_informations, :details
  end
end
