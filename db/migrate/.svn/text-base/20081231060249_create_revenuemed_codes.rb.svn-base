class CreateRevenuemedCodes < ActiveRecord::Migration
  def up
    create_table :revenuemed_codes do |t|
       t.column :revenuemed_group_code, :string
      t.column :revenuemed_adjustment_code, :string
      t.column :revenuemed_code_description, :string

      t.timestamps
    end
  end

  def down
    drop_table :revenuemed_codes
  end
end
