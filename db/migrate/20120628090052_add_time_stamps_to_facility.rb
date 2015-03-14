class AddTimeStampsToFacility < ActiveRecord::Migration
  def change
    add_column :facilities, :created_at, :datetime
    add_column :facilities, :updated_at, :datetime
  end
end
