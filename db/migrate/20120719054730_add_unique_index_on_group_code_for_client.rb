class AddUniqueIndexOnGroupCodeForClient < ActiveRecord::Migration
  def change
    add_index :clients, :group_code, :name => "clients_group_code_index", :unique => true
  end
end
