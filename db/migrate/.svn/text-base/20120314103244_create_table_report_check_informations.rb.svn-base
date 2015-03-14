class CreateTableReportCheckInformations < ActiveRecord::Migration
  
  def up
    create_table :report_check_informations do |t|
      t.column :batch_id, :integer
      t.column :job_id, :integer
      t.column :check_information_id, :integer
      t.column :batch_processing_start_time, :datetime
      t.column :batch_processing_end_time, :datetime
      t.column :image_count, :integer
      t.column :check_amount, :decimal, :precision => 10, :scale => 2
      t.column :total_indexed_amount, :decimal, :precision => 10, :scale => 2
      t.column :total_eobs, :integer
      t.column :total_eobs_with_mpi_success, :integer
      t.column :total_eobs_with_mpi_failure, :integer
      t.column :is_self_pay, :boolean
      t.timestamps
    end
    execute "ALTER TABLE report_check_informations
            ADD CONSTRAINT batch_id_fk FOREIGN KEY (batch_id) REFERENCES batches(id),
            ADD CONSTRAINT job_id_fk FOREIGN KEY (job_id) REFERENCES jobs(id),
            ADD CONSTRAINT check_information_id_fk FOREIGN KEY (check_information_id) REFERENCES check_informations(id)"
  end

  def down
    drop_table :report_check_informations
  end
  
end
