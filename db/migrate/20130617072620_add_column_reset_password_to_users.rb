class AddColumnResetPasswordToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reset_password, :boolean, :default => 0
  end
end
