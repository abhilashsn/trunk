class AddCreatedAtUpdatedAtToPayers < ActiveRecord::Migration
  def up
     add_column :payers, :created_at, :datetime
     add_column :payers, :updated_at, :datetime
  end

  def down
     remove_column :payers, :created_at
     remove_column :payers, :updated_at
  end
end
