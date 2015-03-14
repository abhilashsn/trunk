class CreateTableOutboundFileInformation < ActiveRecord::Migration
  def up
    create_table :outbound_file_informations do |t|
      t.column :name, :string
      t.column :size, :string, :limit=>64
      t.column :sent_at, :datetime
      t.timestamps
    end
  end

  def down
    drop_table :outbound_file_informations
  end
end
