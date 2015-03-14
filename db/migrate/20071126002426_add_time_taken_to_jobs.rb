class AddTimeTakenToJobs < ActiveRecord::Migration
  def up
    add_column :jobs,:time_taken,:integer 
  end

  def down
    remove_column :jobs,:time_taken
  end
end
