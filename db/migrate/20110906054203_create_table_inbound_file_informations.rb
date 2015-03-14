class CreateTableInboundFileInformations < ActiveRecord::Migration
  def up
    create_table :inbound_file_informations do |t|
      t.column :name, :string
      t.column :size, :string, :limit=>64
      t.column :arrival_time, :datetime
      t.column :load_start_time, :datetime
      t.column :load_end_time, :datetime
      t.timestamps
    end
  end

  def down
    drop_table :inbound_file_informations
  end  
end
