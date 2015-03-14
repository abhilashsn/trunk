class AddOcrTimeStampColumnsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :ocr_file_sent_time, :datetime
    add_column :jobs, :ocr_expected_arrival_time, :datetime
    add_column :jobs, :ocr_file_arrived_time, :datetime
  end
end
