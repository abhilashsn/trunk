class AddColumnInJobsForSuperQaOperation < ActiveRecord::Migration
  def up    
    execute "alter table jobs add column work_queue_flagtime datetime"
  end

  def down
    execute "alter table jobs drop column work_queue_flagtime"
  end
end
