class AddDetailsColumnToReasonCodesJobs < ActiveRecord::Migration
  def change
    add_column :reason_codes_jobs, :details, :text
  end
end
