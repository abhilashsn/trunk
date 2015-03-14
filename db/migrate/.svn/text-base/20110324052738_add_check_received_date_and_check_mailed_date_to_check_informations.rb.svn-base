class AddCheckReceivedDateAndCheckMailedDateToCheckInformations < ActiveRecord::Migration
  def up
    add_column :check_informations, :check_received_date, :date
    add_column :check_informations, :check_mailed_date, :date

  end

  def down
    remove_column :check_informations, :check_received_date
    remove_column :check_informations, :check_mailed_date
  end
end
