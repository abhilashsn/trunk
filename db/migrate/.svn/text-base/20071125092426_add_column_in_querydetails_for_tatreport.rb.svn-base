class AddColumnInQuerydetailsForTatreport < ActiveRecord::Migration
  def up
    add_column :query_details, :from_time,  :string
    add_column :query_details, :to_time,  :string
  end

  def down
    remove_column :query_details, :from_time
    remove_column :query_details, :to_time
  end
end
