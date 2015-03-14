class RemoveColumnHipaaGroupCodeFromHipaaCodes < ActiveRecord::Migration
  def up
    remove_column :hipaa_codes, :hipaa_group_code
  end

  def down
    add_column :hipaa_codes, :hipaa_group_code, :string
  end
end
