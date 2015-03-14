class AddColumnDeletedAtToPayers < ActiveRecord::Migration
  def up
    begin
      add_column :payers, :deleted_at,  :datetime
    rescue
    end
  end

  def down
    remove_column :payers, :deleted_at
  end
end
