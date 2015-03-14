class AddColumnInitialImageNameToJobs < ActiveRecord::Migration
  def change
    add_column :jobs,:initial_image_name, :string
  end
end
