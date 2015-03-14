class RemoveCheckInformationIdFromMicrLineInformations < ActiveRecord::Migration
  def up
    execute "ALTER TABLE micr_line_informations DROP FOREIGN KEY micr_line_informations_idfk_1"
    remove_column :micr_line_informations, :check_information_id
  end

  def down
    add_column :micr_line_informations, :check_information_id, :integer
    execute "ALTER TABLE micr_line_informations
       ADD CONSTRAINT micr_line_informations_idfk_1 FOREIGN KEY (check_information_id)
             REFERENCES check_informations(id)"
  end
end
