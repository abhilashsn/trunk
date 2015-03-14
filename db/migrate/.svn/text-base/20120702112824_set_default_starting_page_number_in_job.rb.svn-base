class SetDefaultStartingPageNumberInJob < ActiveRecord::Migration
  def up
    change_column :jobs, :starting_page_number, :integer, :default => 0
  end

  def down
    change_column :jobs, :starting_page_number, :integer
  end
end
