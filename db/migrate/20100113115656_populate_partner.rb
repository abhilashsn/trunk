class PopulatePartner < ActiveRecord::Migration
  def up
     execute "INSERT INTO partners(name) VALUES('REVENUE MED')"
  end

  def down
  end
end
