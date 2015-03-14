class AddColumnDeletedAtToJobs < ActiveRecord::Migration
  def up
    begin
     add_column :jobs, :deleted_at,  :datetime
    rescue
    end
  end

  def down
    remove_column :jobs, :deleted_at
  end
end
