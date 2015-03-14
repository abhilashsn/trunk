class CreateHipaaCodes < ActiveRecord::Migration
  def up
    create_table :hipaa_codes do |t|
      t.column :hipaa_group_code, :string
      t.column :hipaa_adjustment_code, :string
      t.column :hipaa_code_description, :string
      t.timestamps
    end
  end

  def down
    drop_table :hipaa_codes
  end
end
