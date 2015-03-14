class AddProviderPhoneNumberAndSocialSecurityNumberToClaimInformations < ActiveRecord::Migration
  def up
    attributes = ["provider_phone_number","social_security_number"]
    if !(attributes - ClaimInformation.column_names).empty?
         execute "ALTER TABLE claim_informations
     ADD (provider_phone_number  varchar(50),
          social_security_number  varchar(50) );"
    end
  end

  def down
    execute "ALTER TABLE claim_informations
      DROP provider_phone_number  varchar(50),
      DROP social_security_number  varchar(50) );"
  end

  def connection
    ClaimInformation.connection
  end

end
