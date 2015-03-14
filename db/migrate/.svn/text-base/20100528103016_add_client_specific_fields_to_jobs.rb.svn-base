class AddClientSpecificFieldsToJobs < ActiveRecord::Migration
  def up
    add_column :jobs, :client_specific_fields, :text
  end

  def down
    remove_column :jobs, :client_specific_fields
  end
end
