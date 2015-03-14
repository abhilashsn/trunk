class CreateContactInformations < ActiveRecord::Migration
  def up
    create_table :contact_informations do |t|
      t.column :address_line_one, :string, :limit => 100
      t.column :address_line_two, :string, :limit => 100 
      t.column :address_line_three, :string, :limit => 100 
      t.column :city, :string, :limit => 50 
      t.column :state, :string, :limit => 50 
      t.column :zip, :string, :limit => 10 
      t.column :entity, :string, :limit => 10 
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.timestamps
    end
  end

  def down
    drop_table :contact_informations
  end
end
