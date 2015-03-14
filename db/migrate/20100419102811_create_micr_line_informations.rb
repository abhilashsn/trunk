class CreateMicrLineInformations < ActiveRecord::Migration
  def up
    create_table :micr_line_informations do |t|
      t.column :aba_routing_number, :string, :limit => 9
      t.column :payer_account_number, :string, :limit => 15
      t.column :check_information_id, :integer
      t.column :payer_id, :integer
      t.column :status, :string, :default => 'New'
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
    execute "ALTER TABLE micr_line_informations
       ADD CONSTRAINT micr_line_informations_idfk_1 FOREIGN KEY (check_information_id)
             REFERENCES check_informations(id)"
    execute "ALTER TABLE micr_line_informations
       ADD CONSTRAINT micr_line_informations_idfk_2 FOREIGN KEY (payer_id)
             REFERENCES payers(id)"
  end

  def down
    execute "ALTER TABLE micr_line_informations DROP FOREIGN KEY micr_line_informations_idfk_1"
    execute "ALTER TABLE micr_line_informations DROP FOREIGN KEY micr_line_informations_idfk_2"
    drop_table :micr_line_informations
  end
end
