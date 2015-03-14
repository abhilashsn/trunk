class AddIndexToTheFmReportRelatedTables < ActiveRecord::Migration
  def change
    add_index :batches, :date
    add_index :client_reported_errors, :batch_date
    add_index :client_reported_errors, :user_date
    add_index :output_activity_logs, :status 
    add_index :output_activity_logs, :batch_id
    add_index :mpi_statistics_reports, :eob_id
    add_index :image_types, :images_for_job_id
    add_index :image_types, :insurance_payment_eob_id
  end
end
