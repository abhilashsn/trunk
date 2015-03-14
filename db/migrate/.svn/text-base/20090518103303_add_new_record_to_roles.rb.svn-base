class AddNewRecordToRoles < ActiveRecord::Migration
  def up
    execute "INSERT INTO roles(name) VALUES('facility')"
  end

  def down
    Role.destroy(:name=>"facility")
  end
end
