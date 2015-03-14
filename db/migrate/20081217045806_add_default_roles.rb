class AddDefaultRoles < ActiveRecord::Migration
  def up
    roles = ["admin","supervisor","manager","processor", "qa","client","TL"]
    roles.each do |vl|
      execute "INSERT INTO roles(name) VALUES('#{vl}')"
    end
  end

  def down
    Role.destroy_all
  end
end
