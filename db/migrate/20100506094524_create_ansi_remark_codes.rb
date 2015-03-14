class CreateAnsiRemarkCodes < ActiveRecord::Migration
  def up
    create_table :ansi_remark_codes do |t|
      t.column :adjustment_code, :string
      t.column :adjustment_code_description, :string
      
      t.timestamps
    end
  end

  def down
    drop_table :ansi_remark_codes
  end
end
