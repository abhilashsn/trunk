class RemoveCheckInformationIdFkFromReasonCodes < ActiveRecord::Migration
  def up
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY fk_check_information_id"
  end

  def down
    execute "ALTER TABLE reason_codes ADD CONSTRAINT fk_check_information_id FOREIGN KEY (check_information_id)
              REFERENCES check_informations(id)"
  end
end
