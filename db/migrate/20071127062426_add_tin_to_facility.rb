class AddTinToFacility < ActiveRecord::Migration
  def up
     add_column :facilities,:facility_tin,:string
  end

  def down
      remove_column :facilities,:facility_tin
  end
end
