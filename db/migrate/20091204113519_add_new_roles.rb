class AddNewRoles < ActiveRecord::Migration
  def up
    execute "INSERT INTO roles(name) VALUES('lockbox')"
  end

  def down
    Role.destroy_all
  end
end
