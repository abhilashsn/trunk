class AlterFacility < ActiveRecord::Migration
  
  def up
        add_column :clients,:partner_id,:integer
  end

  def down
    remove_column :clients,:partner_id
  end

end
