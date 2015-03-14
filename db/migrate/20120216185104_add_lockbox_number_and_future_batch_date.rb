class AddLockboxNumberAndFutureBatchDate < ActiveRecord::Migration
  def up
    add_column :facility_cut_relationships, :expected_day_of_arrival, :string
    add_column :facility_cut_relationships, :lockbox_number, :string
  end

  def down
    remove_column :facility_cut_relationships, :expected_day_of_arrival
    remove_column :facility_cut_relationships, :lockbox_number
  end
end
