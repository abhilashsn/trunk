class ChangeHipaaCodeDescriptionLengthInHipaaCodes < ActiveRecord::Migration
  def up
  change_column :hipaa_codes, :hipaa_code_description, :string, :limit => 2000
  end

  def down
  change_column :hipaa_codes, :hipaa_code_description, :string
  end
end
