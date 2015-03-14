class SetActiveIndicatorToTrueByDefaultInHipaaCodes < ActiveRecord::Migration
  def up
    change_column :hipaa_codes, :active_indicator, :boolean, :default => 1
  end

  def down
    change_column :hipaa_codes, :active_indicator, :boolean
  end
end
