namespace :reason_codes_cleanup do
  
    desc "To do data migration and clean up related to Reason code DB model change."
    task :rcmigrate => :environment do
      sqls = Array.new
      # rename the reason_codes to reason_codes_new
      sqls << 'RENAME TABLE reason_codes TO reason_codes_old'
      # create a new reason_codes from the old table. 
      sqls << 'CREATE TABLE reason_codes LIKE reason_codes_old'
      # create a temporary hippa_code_id column in reason_codes_clients_facilities_set_names for migration
      sqls << 'alter table reason_codes_clients_facilities_set_names add column hipaa_code_id int(11)'
      # create a temporary ansi_id column in reason_codes_clients_facilities_set_names for migration
      sqls << 'alter table reason_codes_clients_facilities_set_names add column ansi_remark_code_id int(11)'
      # populate distinct reason_code, reason_description combination to new reason_codes table
      sqls << 'insert into reason_codes (reason_code, reason_code_description) (select distinct reason_code, reason_code_description from reason_codes_old)'
      #populate payer based reason code/ desc along with hippa and ansi code to reason_codes_clients_facilities_set_names table
      sqls << 'insert into reason_codes_clients_facilities_set_names (reason_code_id,payer_id, code_status,hipaa_code_id,ansi_remark_code_id ) (select rc.id, rco.payer_id, rco.new_code_status,rco.hipaa_code_id,rco.ansi_remark_code_id from  reason_codes rc, reason_codes_old rco where rc.reason_code=rco.reason_code and rc.reason_code_description=rco.reason_code_description)'
      #populate the hippacode and reason_codes_clients_facilities_set_name_id mapping
      sqls << 'insert into reason_codes_clients_facilities_set_names_hipaa_codes (reason_codes_clients_facilities_set_name_id,hipaa_code_id) select id,hipaa_code_id from reason_codes_clients_facilities_set_names where hipaa_code_id is not null'
      #populate the ansi code and reason_codes_clients_facilities_set_name_id mapping
      sqls << 'insert into reason_codes_ansi_remark_codes (reason_code_id,ansi_remark_code_id) select distinct reason_code_id, ansi_remark_code_id from reason_codes_clients_facilities_set_names where ansi_remark_code_id is not null'
      #dropping the temporary column hipaa_code_id from reason_codes_clients_facilities_set_names
      sqls << 'alter table reason_codes_clients_facilities_set_names drop column hipaa_code_id'
      #dropping the temporary column ansi_remark_code_id from reason_codes_clients_facilities_set_names
      sqls << 'alter table reason_codes_clients_facilities_set_names drop column ansi_remark_code_id'
      # used to connect active record to the database
      ActiveRecord::Base.establish_connection
      # execute each sql
      sqls.each do |sql|
        ActiveRecord::Base.connection.execute(sql)  
      end
    end
    
    desc "To drop all the columns."
    task :dropcol => :environment do
      sqls = Array.new
      sqls << 'ALTER TABLE reason_codes DROP COLUMN payer_id'
      sqls << 'ALTER TABLE reason_codes DROP COLUMN facility_id'
      sqls << 'ALTER TABLE reason_codes DROP COLUMN ansi_remark_code_id'
      sqls << 'ALTER TABLE reason_codes DROP COLUMN new_code_status'
      sqls << 'ALTER TABLE reason_codes DROP COLUMN hipaa_code_id'
      sqls << 'ALTER TABLE reason_codes DROP COLUMN client_code_id'
      # used to connect active record to the database
      ActiveRecord::Base.establish_connection
      # execute each sql
      sqls.each do |sql|
        ActiveRecord::Base.connection.execute(sql)  
      end
    end
    
  task :devmigrate => [:rcmigrate,:dropcol] do
    puts "Done devmigrate"
  end
  
  desc "To revert the changes done in rcmigrate"
    task :revert_rcmigrate => :environment do
      sqls = Array.new
      #to delete the reason_codes tables
      sqls << 'delete from reason_codes'
      #drop the new reason_codes table
      sqls << 'drop table reason_codes'
      #delete the reason_codes_ansi_remark_codes table
      sqls << 'delete from reason_codes_ansi_remark_codes'
      #delete the reason_codes_clients_facilities_set_names table
      sqls << 'delete from reason_codes_clients_facilities_set_names'
      #delete the reason_codes_clients_facilities_set_names_hipaa_codes table
      sqls << 'delete from reason_codes_clients_facilities_set_names_hipaa_codes'
      #delete the reason_codes_clients_facilities_set_names_client_codes table
      sqls << 'delete from reason_codes_clients_facilities_set_names_client_codes'
      #rename reason_codes to reason_codes
      sqls << 'RENAME TABLE reason_codes_old TO reason_codes'
      # used to connect active record to the database
      ActiveRecord::Base.establish_connection
      # execute each sql
      sqls.each do |sql|
        ActiveRecord::Base.connection.execute(sql)  
      end
    end
  
  
  
  

  

  end
  