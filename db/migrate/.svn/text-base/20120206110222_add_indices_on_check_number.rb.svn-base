class AddIndicesOnCheckNumber < ActiveRecord::Migration
  def up
    add_index(:reason_codes, [:check_number], :unique => false, :name => "by_check_number")
    add_index(:check_informations, [:check_number], :unique => false, :name => "by_check_number")
  end

  def down
    remove_index(:reason_codes, :name => "by_check_number")
    remove_index(:check_informations, :name => "by_check_number")
  end
end
