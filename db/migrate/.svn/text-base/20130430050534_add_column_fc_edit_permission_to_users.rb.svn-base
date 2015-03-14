class AddColumnFcEditPermissionToUsers < ActiveRecord::Migration
  def up
    add_column :users, :fc_edit_permission, :boolean, :default => false
    add_column :users, :grant_fc_edit_permission,:boolean, :default => false
#    User.update_all({:grant_fc_edit_permission => true, :fc_edit_permission => true},
#      {:login => ['rm.shamnathms','rm.mahesh.vr','rm.krishnakumar']})
  end

  def down
    remove_column :users, :fc_edit_permission
    remove_column :users, :grant_fc_edit_permission
  end
end
