class CreateMpiStatisticsReports < ActiveRecord::Migration
  def up
    create_table :mpi_statistics_reports do |t|
      t.column :batch_id, :integer
      t.column :user_id, :integer
      t.column :mpi_status, :string
      t.column :search_criteria, :string
      t.column :start_time, :datetime
    end
    execute "ALTER TABLE mpi_statistics_reports ADD CONSTRAINT mpi_statistics_reports_idfk_1 FOREIGN KEY (batch_id)
           REFERENCES batches(id)"
    execute "ALTER TABLE mpi_statistics_reports ADD CONSTRAINT mpi_statistics_reports_idfk_2 FOREIGN KEY (user_id)
           REFERENCES users(id)"
  end

  def down
    execute "ALTER TABLE mpi_statistics_reports DROP FOREIGN KEY mpi_statistics_reports_idfk_1"
    execute "ALTER TABLE mpi_statistics_reports DROP FOREIGN KEY mpi_statistics_reports_idfk_2"
    drop_table :mpi_statistics_reports
  end
end
