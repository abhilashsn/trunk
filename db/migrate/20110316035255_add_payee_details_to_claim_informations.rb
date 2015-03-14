class AddPayeeDetailsToClaimInformations < ActiveRecord::Migration
  def up
    attributes = ["payee_name","iplan","payee_address_one","payee_city","payee_zipcode","payee_npi","payee_tin"]
    if !(attributes - ClaimInformation.column_names).empty?
         execute "ALTER TABLE claim_informations
     ADD (payee_npi  varchar(255),
          payee_tin  varchar(255) );" 
    end
  end

  def down
    execute "ALTER TABLE claim_informations
      DROP payee_npi  varchar(255),
      DROP payee_tin  varchar(255) );"
     end
  def connection
    ClaimInformation.connection
  end

end
