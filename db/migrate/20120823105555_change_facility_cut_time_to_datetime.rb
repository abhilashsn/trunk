class ChangeFacilityCutTimeToDatetime < ActiveRecord::Migration
  def change
    change_column :facility_cut_relationships, :time, :datetime
  end
end
