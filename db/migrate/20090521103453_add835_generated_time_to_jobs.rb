class Add835GeneratedTimeToJobs < ActiveRecord::Migration
  def up
    add_column :jobs, :output_835_generated_time, :datetime ,:default =>'0000-00-00 00:00:00'
  end

  def down
    remove_column :jobs, :output_835_generated_time 
  end
end
