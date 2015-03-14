class ChangeTheDataTypeOfExpectedArrivalDateInInboundFileInformations < ActiveRecord::Migration
  def up
    change_column :inbound_file_informations, :expected_arrival_date, :datetime
  end

  def down
    change_column :inbound_file_informations, :expected_arrival_date, :date
  end
end
