class AddColumnDeletedAtToCheckInformations < ActiveRecord::Migration
  def up
    begin
      add_column :check_informations, :deleted_at,  :datetime
     rescue
    end
  end

  def down
    remove_column :check_informations, :deleted_at
  end
end
