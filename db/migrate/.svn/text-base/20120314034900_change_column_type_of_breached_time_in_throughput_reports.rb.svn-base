class ChangeColumnTypeOfBreachedTimeInThroughputReports < ActiveRecord::Migration
  def up
     execute <<-SQL
     UPDATE throughput_reports SET breached_time = NULL
    SQL
    change_column :throughput_reports, :breached_time, :datetime
  end

end
