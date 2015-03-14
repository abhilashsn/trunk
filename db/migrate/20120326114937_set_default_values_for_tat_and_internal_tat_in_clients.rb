class SetDefaultValuesForTatAndInternalTatInClients < ActiveRecord::Migration
  def change
    change_column :clients, :tat, :int, :default => 24
    change_column :clients, :internal_tat, :int, :default => 20
  end
end
