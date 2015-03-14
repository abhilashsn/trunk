class CreatePartners < ActiveRecord::Migration
  def up
    create_table :partners do |t|
  t.column :name, :string
    end
  end

  def down
    drop_table :partners
  end
end
