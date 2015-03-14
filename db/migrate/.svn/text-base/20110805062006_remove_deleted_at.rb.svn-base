class RemoveDeletedAt < ActiveRecord::Migration
  def up
    remove_column :batches, :deleted_at
    remove_column :jobs, :deleted_at
    remove_column :images_for_jobs, :deleted_at
    remove_column :client_images_to_jobs, :deleted_at
    remove_column :check_informations, :deleted_at
    remove_column :payers, :deleted_at
    remove_column :reason_codes, :deleted_at
  end

  def down
    add_column :batches, :deleted_at,  :datetime 
    add_column :jobs, :deleted_at,  :datetime
    add_column :images_for_jobs, :deleted_at,  :datetime
    add_column :client_images_to_jobs, :deleted_at,  :datetime
    add_column :check_informations, :deleted_at,  :datetime
    add_column :payers, :deleted_at,  :datetime
    add_column :reason_codes, :deleted_at,  :datetime
  end
end
