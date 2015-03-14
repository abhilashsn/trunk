class ChangeColumnTypeOfBreachedTimeInThroughputReportBreachedInformations < ActiveRecord::Migration
  def up
    execute <<-SQL
     UPDATE throughput_report_breached_informations SET breached_time = NULL
    SQL
    change_column :throughput_report_breached_informations, :breached_time, :datetime
  end
end
