class AddEobIdEobTypeToMpiStatisticsReports < ActiveRecord::Migration
  def up
    add_column :mpi_statistics_reports, :eob_id,  :integer
    add_column :mpi_statistics_reports, :eob_type,  :string
  end

  def down
    remove_column :mpi_statistics_reports, :eob_id
    remove_column :mpi_statistics_reports, :eob_type
  end
end
