class AddStartingPageNumberToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :starting_page_number, :integer
  end
end
