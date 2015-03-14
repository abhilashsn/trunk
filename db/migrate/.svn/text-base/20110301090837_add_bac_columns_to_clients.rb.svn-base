class AddBacColumnsToClients < ActiveRecord::Migration
  def up
      add_column :clients, :group_code, :string, :limit=>10 
    add_column :clients, :type_code, :string, :limit=>10 
    add_column :clients, :type_desc, :string, :limit=>100 
    add_column :clients, :channel, :string, :limit=>50
    add_column :clients, :partener_bank_group_code, :string, :limit=>50 
end

def down
        remove_column :clients, :group_code
      remove_column :clients, :type_code
      remove_column :clients, :type_desc
      remove_column :clients, :channel
      remove_column :clients, :partener_bank_group_code
  end
end
