class AddPayeeNpiTinToCheckInformations < ActiveRecord::Migration
  def change
         add_column :check_informations, :payee_npi, :string , :limit => 10
         add_column :check_informations, :payee_tin, :string, :limit => 9
   end
end
