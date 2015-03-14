class ChangeGroupCodeToNotNullInClient < ActiveRecord::Migration
  def up
	  change_column :clients, :group_code, :string, :limit => 10, :null => false
  end

  def down
	  change_column :clients, :group_code, :string, :limit => 10
  end
end
