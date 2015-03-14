class AddProcessorCommentsToJobs < ActiveRecord::Migration
  def up
    add_column :jobs,:processor_comments,:string,:default =>'null'
  end

  def down
    remove_column :jobs,:processor_comments
  end
end
