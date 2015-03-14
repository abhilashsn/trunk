class AddPayidToCheckinformations < ActiveRecord::Migration
  def up
    add_column :check_informations,:payid,:string
  end

  def down
     remove_column :check_informations,:payid
  end
  end

