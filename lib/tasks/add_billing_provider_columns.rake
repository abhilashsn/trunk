namespace :add_billing_provider_detail do
  desc "To add the billing provider columns."
    task :columns => :environment do
      ActiveRecord::Base.establish_connection :mpi_data
      ActiveRecord::Base.connection.execute("ALTER TABLE `claim_informations` ADD `billing_provider_tin` VARCHAR( 14 ) NULL AFTER `payee_tin` ,ADD `billing_provider_npi` VARCHAR( 14 ) NULL AFTER `billing_provider_tin` ,ADD `billing_provider_address_one` VARCHAR( 100 ) NULL AFTER `billing_provider_npi` ,ADD `billing_provider_city` VARCHAR( 30 ) NULL AFTER `billing_provider_address_one` ,ADD `billing_provider_state` VARCHAR( 5 ) NULL AFTER `billing_provider_city` ,ADD `billing_provider_zipcode` VARCHAR( 10 ) NULL AFTER `billing_provider_state`;")
    end
end