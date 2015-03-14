class AddDefaultForFootnoteIndicatorInPayers < ActiveRecord::Migration
  def up
    change_column :payers, :footnote_indicator, :boolean, :default => 0
  end

  def down
    change_column :payers, :footnote_indicator, :boolean
  end
end
