class AddDetailsToFacilities < ActiveRecord::Migration
  def up
    begin
    add_column :facilities, :details, :text
    rescue
    end
  end

  def down
    remove_column :facilities, :details
  end
end
