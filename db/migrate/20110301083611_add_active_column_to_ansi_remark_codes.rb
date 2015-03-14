class AddActiveColumnToAnsiRemarkCodes < ActiveRecord::Migration
  def up
    add_column :ansi_remark_codes, :active, :boolean
  end

  def down
    remove_column :ansi_remark_codes, :active
  end
end

