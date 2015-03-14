class AddOutputActivityLogIdToClaimFileInformations < ActiveRecord::Migration
  def change
    add_column :claim_file_informations, :output_activity_log_id, :integer
     #adding the foreign key
     execute <<-SQL
      ALTER TABLE claim_file_informations
        ADD CONSTRAINT fk_output_activity_log_id
        FOREIGN KEY (output_activity_log_id)
        REFERENCES output_activity_logs(id)
     SQL
  end
end
