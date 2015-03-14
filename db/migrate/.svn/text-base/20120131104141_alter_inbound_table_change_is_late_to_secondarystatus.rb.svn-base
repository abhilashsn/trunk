class AlterInboundTableChangeIsLateToSecondarystatus < ActiveRecord::Migration
  def up
    remove_column :inbound_file_informations, :is_late
    add_column :inbound_file_informations, :secondary_status, :string, :limit=>64
  end

  def down
    remove_column :secondary_status
    add_column :inbound_file_informations, :is_late, :boolean    
  end
end
