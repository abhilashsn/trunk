class AddNavicurePayeridToCheckinformation < ActiveRecord::Migration
  def up
     add_column :check_informations,:navicure_payid,:string
  end

  def down
    remove_column :check_informations,:navicure_payid
  end
end
