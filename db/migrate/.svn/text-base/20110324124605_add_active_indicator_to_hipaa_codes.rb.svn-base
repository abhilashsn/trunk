class AddActiveIndicatorToHipaaCodes < ActiveRecord::Migration
  def up
    add_column :hipaa_codes, :active_indicator, :boolean
  end

  def down
    remove_column :hipaa_codes, :active_indicator
  end
end
