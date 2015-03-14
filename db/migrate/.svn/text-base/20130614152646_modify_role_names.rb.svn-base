class ModifyRoleNames < ActiveRecord::Migration
  def up
    execute "UPDATE roles SET name = 'partner' WHERE name = 'client'"
    execute "UPDATE roles SET name = 'client' WHERE name = 'facility'"
    execute "UPDATE roles SET name = 'facility' WHERE name = 'lockbox'"
  end

  def down
    execute "UPDATE roles SET name = 'client' WHERE name = 'partner'"
    execute "UPDATE roles SET name = 'facility' WHERE name = 'client'"
    execute "UPDATE roles SET name = 'lockbox' WHERE name = 'facility'"
  end
end
