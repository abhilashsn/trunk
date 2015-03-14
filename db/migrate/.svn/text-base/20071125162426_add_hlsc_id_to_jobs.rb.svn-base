class AddHlscIdToJobs < ActiveRecord::Migration
  def up
    add_column :jobs, :hlsc_id, :integer,:references => :users
   
  end

  def down
   
    remove_column :jobs, :hlsc_id
  end
end
