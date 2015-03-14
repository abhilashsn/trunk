class AddNewColumnsToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :claim_file_count_for_mon, :integer
    add_column :facilities, :claim_file_count_for_tue, :integer
    add_column :facilities, :claim_file_count_for_wed, :integer
    add_column :facilities, :claim_file_count_for_thu, :integer
    add_column :facilities, :claim_file_count_for_fri, :integer
    add_column :facilities, :claim_file_count_for_sat, :integer
    add_column :facilities, :claim_file_count_for_sun, :integer
  end

  def down
    remove_column :facilities, :claim_file_count_for_mon
    remove_column :facilities, :claim_file_count_for_tue
    remove_column :facilities, :claim_file_count_for_wed
    remove_column :facilities, :claim_file_count_for_thu
    remove_column :facilities, :claim_file_count_for_fri
    remove_column :facilities, :claim_file_count_for_sat
    remove_column :facilities, :claim_file_count_for_sun
  end
end
