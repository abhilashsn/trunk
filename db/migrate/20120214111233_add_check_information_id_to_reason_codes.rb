class AddCheckInformationIdToReasonCodes < ActiveRecord::Migration
  def change
    add_column :reason_codes, :check_information_id, :integer
    #Adding foreign key
    execute <<-SQL
      ALTER TABLE reason_codes
        ADD CONSTRAINT fk_check_information_id
        FOREIGN KEY (check_information_id)
        REFERENCES check_informations(id)
     SQL
  end
end
