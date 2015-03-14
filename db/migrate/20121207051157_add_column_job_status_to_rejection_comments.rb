class AddColumnJobStatusToRejectionComments < ActiveRecord::Migration
  def change
    add_column :rejection_comments, :job_status, :string, :default => "incomplete"
  end
end
