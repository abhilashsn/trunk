class AddColumnDeletedAtToReasoncodes < ActiveRecord::Migration
  def up
    begin
     add_column :reason_codes, :deleted_at,  :datetime
     rescue
    end
  end

  def down
    remove_column :reason_codes, :deleted_at
  end
end
