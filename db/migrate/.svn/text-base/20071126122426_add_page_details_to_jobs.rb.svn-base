class AddPageDetailsToJobs < ActiveRecord::Migration
  def up
    add_column :jobs, :pages_from,:integer
     add_column :jobs, :pages_to,:integer
  end

  def down
    remove_column :jobs, :pages_from
    remove_column :jobs, :pages_to
  end
end
