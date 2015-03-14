namespace :dataimport do
  desc "Rake to set the upload start time for PDS"
  task :set_upload_start_time, [:file_name, :upload_start_time] => :environment do |t, args|
    begin
      converted_time = Time.strptime("#{args.upload_start_time}", '%Y-%m-%d %H:%M:%S').utc
      OutputActivityLog.where( :file_name => args.file_name).update_all(:upload_start_time => converted_time)
    rescue Exception => e
      if(e.message == 'invalid date')
        puts " Invalid Date Format. Expected format is YYYY-MM-DD HH:MM:SS"
      else
        puts e.message
      end
    end
  end

  desc "Rake to set the upload end time for PDS"
  task :set_upload_end_time, [:file_name, :upload_end_time] => :environment do |t, args|
    begin
      converted_time = Time.strptime("#{args.upload_end_time}", '%Y-%m-%d %H:%M:%S').utc
      OutputActivityLog.where(:file_name => args.file_name).update_all(:upload_end_time => converted_time)
    rescue Exception => e
      if(e.message == 'invalid date')
        puts " Invalid Date Format. Expected format is YYYY-MM-DD HH:MM:SS"
      else
        puts e.message
      end
    end
  end

  desc "Import Ansi code from the csv file mentioned in the path"
  task :ansi_code => :environment do
    #ansicode.csv
    load_data do |row|
      process_ansi_code row
    end
  end
  
  desc "Import csv file for processing the clients"
  task :client_profile_group => :environment do
    #client_profile_group.csv
    load_data do |row|
      process_client_profile_group row
    end
  end
  
  desc "populate facilities table from the csv "
  task :facilities => :environment do
    #client_profile_site.csv
    load_data do |row|
      process_facilities row
    end
  end

  desc "process csv containing payers"
  task :rcc_payer => :environment do
    #rcc_payer.csv
    load_data do |row|
      process_payer row      
    end
  end

  desc "create temp_reason_codes table and populate from rcc_reason_codes"  
  task :temp_reason_codes => :environment do
    #rcc_reason_codes.csv
    create_temporary_reason_code
  end

  desc "create temp_reason_code_mapping table and populate from csv"
  task :temp_reason_code_mappings => :environment do
    #rcc_mappings.csv
    create_temporary_reason_mapping_code
  end

  desc "create temp_lockbox table and populate from csv"
  task :temp_lockbox => :environment do
    #client_profile_lockbox.csv
    create_temporary_lockbox
  end

  desc "create temp_payer table and populate from csv "
  task :temp_payers => :environment do
    create_temporary_payers
  end
  

  desc "process realationshipf from the temp tables temp_reason_codes and temp_reason_code_mapping table and update payer table and micr_line_information table"
  task :process_relationships_from_temp_tables => :environment do
    insert_reason_code
    loading_client_code
    update_payer_id_on_temp_reason_codes
    update_reason_code
    update_hipaa_code_master
    update_hipaa_code_id
    update_client_id
    update_facility_id
    update_client_code_id
    populate_reason_codes_facilities_payers
    populate_reason_codes_clients_facilities_set_names_id
    populate_reason_codes_clients_facilities_set_names_client_codes
    populate_reason_codes_clients_facilities_set_names_hipaa_codes
    populate_facility_lockbox_mapping

    
    update_payer_info
    insert_micr_line_informations
  end  

  desc "change partner to BAC for clients"
  task :change_partner_to_bac => :environment do
    make_bac_as_partner
  end


  desc "remove all the temperory tables"
  task :remove_temp_tables => :environment do
    remove_temp_tables
  end  

  desc "wrapper task which will invoke all the tasks in order"
  task :load_csv_files_and_do_mappings => :environment do
    load_all_tasks_in_order
  end

  desc "Remove the client_id for the site level crosswalk"
  task :remove_client_id_for_site_level_crosswalk => :environment do
    sql = "UPDATE reason_codes_clients_facilities_set_names SET client_id = NULL WHERE facility_id IS NOT NULL "
    ActiveRecord::Base.connection.execute(sql) 
  end
  
end



# invoke all the rake task in order, the files for each
# rake taks is found in the variable tasks and files
def load_all_tasks_in_order
  load_dir = ENV["load_dir"]
  tasks_and_files= [{"ansi_code"=>"ansicode.csv"},
    {"client_profile_group"=>"clients.csv"},
    {"facilities"=>"facilities.csv"},
    {"rcc_payer"=>"rcc_payer.csv"},
    {"temp_reason_codes"=>"rcc_reason_codes.csv"},
    {"temp_reason_code_mappings"=>"rcc_mappings.csv"},
    {"temp_lockbox"=>"client_profile_lockbox.csv"},
    {"temp_payers"=>"ABAInfo.csv"},
    {"process_relationships_from_temp_tables"=>""},
    {"change_partner_to_bac"=>""},
    {"remove_temp_tables" =>""}]
  errors = []
  
  errors << "Please provide a valid directory" if (load_dir.blank? || !FileTest.exists?(load_dir))
  if errors.empty?
    tasks_and_files.each do |hash|
      csv_file  = hash[hash.keys[0]]
      if !csv_file.blank?
        abs_path = load_dir + "/" + csv_file
        errors << "File #{csv_file} not found in #{load_dir}" if ! FileTest.exists?(abs_path)
      end
    end
  end

  if errors.empty?
    tasks_and_files.each do |hash|
      task = hash.keys[0]
      csv_file  = hash[task]
      if !csv_file.blank?
        abs_path = load_dir + "/" + csv_file
        ENV["path"] = abs_path
        puts "processing file " + ENV["path"]
      end
      puts "invoking task dataimport:#{task} ......"
      Rake::Task["dataimport:#{task}"].invoke  
    end
  else
    errors.each do |err|
      puts err + "\n"
    end
  end   
end






def create_temporary_lockbox
  path = ENV["path"]
  if !path.blank? && FileTest.exists?(path)

    sql=<<END
  CREATE TABLE `temp_lockbox` (
  `sitecode` varchar(10) DEFAULT NULL,
  `lockbox_number` varchar(10) DEFAULT NULL,
  `lockbox_location_code` varchar(10) DEFAULT NULL,
  `lockbox_location_name` varchar(255) DEFAULT NULL
   )
END
    
    load_sql=<<END
  LOAD DATA LOCAL INFILE '#{path}'
  INTO TABLE temp_lockbox 
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES
  (sitecode,lockbox_number,lockbox_location_code,lockbox_location_name);  
END
    ["DROP TABLE IF EXISTS temp_lockbox",sql,load_sql].each do |sql|
      execute_sql(sql)
    end
  else
    puts "Error please provide a valid file: " 
  end
end


def create_temporary_payers
  path = ENV["path"]
  if !path.blank? && FileTest.exists?(path)

    creat_sql =<<END
  CREATE TABLE `temp_payer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
    ABA_NUM varchar(100),
    ACCT_NUM varchar(100),
    gateway varchar(100),
 payid  varchar(100),
 O_PAY_ID varchar(100),
 PAYOR varchar(100),
 COUNT varchar(100),
 PAY_ADD1 varchar(100),
 PAY_ADD2 varchar(100),
 PAY_ADD3 varchar(100),
 PAY_ADD4 varchar(100),
 FOOTNOTE_PAYER_INDICATOR varchar(100),
 REASON_CODE_SET varchar(100),
  PRIMARY KEY (`id`)  
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
END


    inst_sql =<<END
LOAD DATA LOCAL INFILE '#{path}'
INTO TABLE temp_payer 
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES
(ABA_NUM,ACCT_NUM,gateway,payid,O_PAY_ID,PAYOR,COUNT,PAY_ADD1,PAY_ADD2,
PAY_ADD3,PAY_ADD4,FOOTNOTE_PAYER_INDICATOR,REASON_CODE_SET);

END
    [creat_sql,
      "CREATE INDEX indx_tp_PAY_ID ON temp_payer (payid);",
      "CREATE INDEX indx_tp_GATEWAY ON temp_payer (gateway);",
      "CREATE INDEX indx_tp_opayid ON temp_payer (O_PAY_ID);",
      inst_sql].each do  |sql|
      execute_sql(sql)
    end
    
  else
    puts "Error please provide a valid file: " 
  end
end

def update_payer_info
  sql=<<END
  update payers p inner join temp_payer tp using (payid,gateway)
  set p.pay_address_one = tp.PAY_ADD1,
  p.pay_address_two = tp.PAY_ADD2,
  p.pay_address_three = tp.PAY_ADD3
  p.status = 'MAPPED'
  p.type = tp.id
  where p.payid = tp.payid
  and p.gateway = tp.gateway 
END
  execute_sql(sql)
end


def insert_micr_line_informations
  sql=<<END
select p.id,tp.ABA_NUM, tp.ACCT_NUM , 'Approved'
from  temp_payer tp inner join  payers p using (payid,gateway)
where tp.payid = p.payid
and tp.gateway = p.gateway 
order by p.id desc
END
  result = execute_sql(sql)
  header_to_fields = {"id"=>"payer_id", "ABA_NUM"=>"aba_routing_number","ACCT_NUM"=>"payer_account_number",'Approved'=>'status'}
  count = 0
  result.each_hash do |row_hash|
    count = count + 1
    hash_to_insert = get_hash_to_insert(row_hash, header_to_fields)
    ml = MicrLineInformation.new(hash_to_insert)
    if ml.valid?
      ml.save
    else
      log_errors_while_mapping "micrlineinformation: ", count
    end
  end
  
end



def create_temporary_reason_code 
  path = ENV["path"]
  if !path.blank? && FileTest.exists?(path)

    creat_sql = <<END
  CREATE TABLE temp_reason_codes (
  id int(11) NOT NULL AUTO_INCREMENT,
  reason_code_id int(11) NOT NULL,
  reason_code_set varchar(255) DEFAULT NULL,
  learn_date date DEFAULT NULL,
  reason_code varchar(255) DEFAULT NULL,
  reason_code_description varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)  
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
END
    load_sql =<<END
LOAD DATA LOCAL INFILE '#{path}'
INTO TABLE temp_reason_codes 
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES
(reason_code_set,learn_date,reason_code,reason_code_description);
END

    [
      "DROP TABLE IF EXISTS temp_reason_codes",
      creat_sql,
      "CREATE INDEX indx_reason_code_set ON temp_reason_codes (reason_code_set);",
      "CREATE INDEX indx_reason_code ON temp_reason_codes (reason_code);",
      "CREATE INDEX indx_reason_code_description ON temp_reason_codes (reason_code_description);",
      "CREATE INDEX indx_trc_reason_code_id ON temp_reason_codes (reason_code_id);",
      load_sql].each do |sql|
      execute_sql(sql) 
    end
  else
    puts "Error please provide a valid file: " 
  end
end


def create_temporary_reason_mapping_code
  path = ENV["path"]
  if !path.blank? && FileTest.exists?(path)

    sql =<<END  
CREATE TABLE `temp_reason_codes_mapping` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reason_code_set` varchar(255) DEFAULT NULL,
  `reason_code` varchar(255) DEFAULT NULL,
  map_level varchar(25) DEFAULT NULL,
  group_code  varchar(25)     DEFAULT NULL,
  site_no  varchar(25)     DEFAULT NULL,
  ansi_reason_code  varchar(25)     DEFAULT NULL,
  client_system_code  varchar(255)     DEFAULT NULL,
  claim_status_code  varchar(255)     DEFAULT NULL,
  denied_ansi_reason_code   varchar(255)     DEFAULT NULL,
  denied_client_system_code   varchar(255)     DEFAULT NULL,
  denied_claim_status_code    varchar(255)     DEFAULT NULL,
  active    varchar(10)     DEFAULT NULL,
  reporting_activity_1_tx     varchar(255)     DEFAULT NULL,
  reporting_activity_2_tx     varchar(255)     DEFAULT NULL,
  payer_id int(10) DEFAULT NULL,
  reason_code_id int(10) DEFAULT NULL,
  client_id int(10) DEFAULT NULL,
  facility_id int(10) DEFAULT NULL,
  hipaa_code_id int(10) DEFAULT NULL,
  client_code_id int(10) DEFAULT NULL,
  reason_code_payer_id int(10) DEFAULT NULL,
  PRIMARY KEY (`id`)  
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

END

    load_sql=<<END
LOAD DATA LOCAL INFILE '#{path}'
INTO TABLE temp_reason_codes_mapping 
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES
(reason_code_set,reason_code,map_level,group_code,site_no,ansi_reason_code,client_system_code,claim_status_code,denied_ansi_reason_code,
denied_client_system_code,denied_claim_status_code,active,reporting_activity_1_tx,reporting_activity_2_tx);
END


    ["DROP TABLE IF EXISTS temp_reason_codes_mapping",sql,
      "CREATE INDEX indx_reason_code_set ON temp_reason_codes_mapping (reason_code_set);",
      "CREATE INDEX indx_trcm_reason_code_set ON temp_reason_codes_mapping (reason_code_set);",
      "CREATE INDEX indx_trcm_reason_code ON temp_reason_codes_mapping (reason_code);",
      "CREATE INDEX indx_trcm_map_level ON temp_reason_codes_mapping (map_level);",
      "CREATE INDEX indx_trcm_group_code ON temp_reason_codes_mapping (group_code);",
      "CREATE INDEX indx_trcm_site_no ON temp_reason_codes_mapping (site_no);",
      "CREATE INDEX indx_trcm_ansi_reason_code ON temp_reason_codes_mapping (ansi_reason_code);",
      "CREATE INDEX indx_trcm_client_system_code ON temp_reason_codes_mapping (client_system_code);",
      "CREATE INDEX indx_trcm_payer_id ON temp_reason_codes_mapping (payer_id);",
      "CREATE INDEX indx_trcm_reason_code_id ON temp_reason_codes_mapping (reason_code_id);",
      "CREATE INDEX indx_trcm_client_id ON temp_reason_codes_mapping (client_id);",
      "CREATE INDEX indx_trcm_facility_id ON temp_reason_codes_mapping (facility_id);",
      "CREATE INDEX indx_trcm_hipaa_code_id ON temp_reason_codes_mapping (hipaa_code_id);",
      "CREATE INDEX indx_trcm_client_code_id ON temp_reason_codes_mapping (client_code_id);",
      load_sql].each do |row|
      execute_sql(row)
    end
  else
    puts "Error please provide a valid file: " 
  end
end




def load_file file
  rowcount = 0
  FCSV.foreach(file, :headers=>true) do |row|
    rowhash = row.to_hash
    rowcount = rowcount + 1
    rowhash["slno"] =  rowcount
    yield rowhash 
  end 
end


#load each row from csv files
def load_data
  path = ENV["path"]
  if !path.blank? && FileTest.exists?(path)
    File.open(path + ".error_rpt","w+") do |f|
      f.write("Errors While inserting to db")
    end 
    rowcount = 0
    FCSV.foreach(path, :headers=>true) do |row|
      rowhash = row.to_hash
      rowcount = rowcount + 1
      rowhash["slno"] =  rowcount
      yield rowhash 
    end 
  else
    puts "Error please provide a valid file: " 
  end
end



def process_ansi_code rowhash
  #puts rowhash["slno"].to_s+"\n"  
  header_to_fields = {"ANSI_CODE"=>"hipaa_adjustment_code","ANSI_CODE_DESCRIPTION"=>"hipaa_code_description"}  
  hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  #puts hash_to_insert.keys.join("||") + "\n"
  #puts hash_to_insert.values.join("||") + "\n"
  hipaa_code = HipaaCode.new(hash_to_insert)
  if hipaa_code.valid?
    hipaa_code.save
  else
    erro_data rowhash, hipaa_code
  end
end

def process_ansi_remark_codes rowhash
  #puts rowhash["slno"].to_s+"\n"  
  header_to_fields = {"ANSI_CODE"=>"adjustment_code","ANSI_CODE_DESCRIPTION"=>"adjustment_code_description", "ACTIVE"=>"active"}  
  hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  #puts hash_to_insert.keys.join("||") + "\n"
  #puts hash_to_insert.values.join("||") + "\n"
  ansi_code = AnsiRemarkCode.new(hash_to_insert)
  if ansi_code.valid?
    ansi_code.save
  else
    erro_data rowhash, ansi_code
  end
end




def process_facilities rowhash
  #header_to_fields = {"GROUP_CODE"=>"group_code","SITE_NAME"=>"name","SITE_NO"=>"sitecode", "RCC_ACTIVE"=>"enable_crosswalk"}
  #header_to_fields = 
  #hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  
  hash_to_insert = rowhash.clone
  hash_to_insert.delete("slno")
  

  facility = Facility.new(hash_to_insert)
  if facility.valid?
    if query_by_attrbutes facility, hash_to_insert
      erro_data rowhash, facility.errors.add("Object", " already exists!")
    else
      facility.save
    end
  else
    erro_data rowhash, facility
  end
end


def process_payer rowhash
  #rcc_payer.csv  
  header_to_fields = {"REASON_CODE_SET_NAME"=>"reason_code_set_name","FOOTNOTE_PAYER"=>"footnote_indicator",
    "GATEWAY"=>"gateway","PAY_ID"=>"payid","PAYER_NAME"=>"payer"}
  hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  payer = Payer.new(hash_to_insert)
  if payer.valid?
    payer.save
  else
    erro_data rowhash, payer
  end
end


def process_reason_code rowhash
  #rcc_reason_codes.csv
  #puts rowhash.keys.join(",")
  header_to_fields= {"REASON_CODE_SET_NAME"=>"","LEARN_DATE,REASON_CODE"=>"","REASON_CODE_DESCRIPTION"=>""}
  hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  payer = Payer.new(hash_to_insert)
  if payer.valid?
    payer.save
  else
    erro_data rowhash, payer
  end
end





def process_client_profile_group rowhash
  #clients.csv
  # header_to_fields =   {"GROUP_NAME"=>"name","GROUP_CODE"=>"group_code","ORG_TYPE_CODE"=>"type_code",
  #   "PARTNER_BANK_GROUP_CD"=>"partener_bank_group_code","SALES_CHANNEL"=>"channel","ORG_TYPE_DESCRIPTION"=>"type_desc","CLIENT TAT"=>'tat'}
  #hash_to_insert = get_hash_to_insert(rowhash,header_to_fields)    
  hash_to_insert = rowhash.clone
  hash_to_insert.delete("slno")
  id = hash_to_insert.delete("id")
  client = Client.new(hash_to_insert)
  if client.valid?
    sql=<<END
    insert into clients (id, #{hash_to_insert.keys.join(",")}) values (#{id}, #{hash_to_insert.values.map{|j| "'" + j.gsub(/'/, "\\\\'") + "'"}.join(",")})
END
    execute_sql(sql)
    #client.save
  else
    erro_data rowhash, client
  end
end




def query_by_attrbutes obj,attributes
  (obj.class).find(:first, :conditions=>attributes)
end


def get_hash_to_insert row,mapper
  hash_to_insert = Hash.new
  mapper.each do |key,value|
    hash_to_insert[value] = row[key]
  end
  hash_to_insert  
end


def erro_data rowhash,model=nil
  path = ENV["path"]
  File.open(path + ".error_rpt","a+") do |f|
    puts ENV["path"] + "\n" +  rowhash["slno"].to_s + ": Cannot be inserted as validations are not met " + (model==nil ? "" : model.errors.full_messages.join(", "))
    puts "\n"
    f.write ("\n " + rowhash["slno"].to_s + ": Cannot be inserted as validations are not met " + (model==nil ? "" : model.errors.full_messages.join(", ")))
  end  
end



#process_relationships

def insert_reason_code
  sql = "SELECT DISTINCT reason_code, reason_code_description from temp_reason_codes where reason_code_description !=''"
  result = execute_sql(sql)
  header_to_fields = {"reason_code"=>"reason_code", "reason_code_description"=>"reason_code_description"}
  count =  0
  result.each_hash do |row_hash|
    count = count + 1
    hash_to_insert = get_hash_to_insert(row_hash, header_to_fields)
    rc = ReasonCode.new(hash_to_insert)
    if rc.valid? && !query_by_attrbutes(rc,hash_to_insert)
      rc.save
    else
      log_errors_while_mapping "update_reason_code", count
    end    
  end
end

def loading_client_code
  sql = "SELECT DISTINCT group_code,client_system_code FROM temp_reason_codes_mapping"
  result = execute_sql(sql)
  count = 0
  header_to_fields = {"group_code"=>"group_code","client_system_code"=>"adjustment_code"} 
  result.each_hash do |row_hash|
    count = count + 1
    hash_to_insert = get_hash_to_insert(row_hash, header_to_fields)
    cc = ClientCode.new(hash_to_insert)
    if cc.valid?  && ! query_by_attrbutes( cc , hash_to_insert)
      cc.adjustment_code_description = "NA"
      cc.save
    else
      log_errors_while_mapping "loading_client_data", count
    end
  end
end



def update_payer_id_on_temp_reason_codes
  sql=<<END
update temp_reason_codes_mapping trcm, payers p set trcm.payer_id = p.id 
where trcm.reason_code_set = p.reason_code_set_name
END
  execute_sql(sql)
end


def update_reason_code_id
  
  sql1 =<<END
update temp_reason_codes trc inner join  reason_codes rc  using (reason_code,reason_code_description) 
set trc.reason_code_id = rc.id
END
  sql2 =<<END
update temp_reason_codes_mapping trcm inner join temp_reason_codes trc using (reason_code_set,reason_code)
set trcm.reason_code_id = trc.reason_code_id
END
  [sql1, sql2].each do |sql|
    execute_sql(sql)
  end

end


def update_reason_code  
  sql1 =<<END
  update temp_reason_codes trc inner join  reason_codes rc  using (reason_code,reason_code_description) 
  set trc.reason_code_id = rc.id
END
  
  sql2 =<<END
  update temp_reason_codes_mapping trcm inner join temp_reason_codes trc using (reason_code_set,reason_code)
  set trcm.reason_code_id = trc.reason_code_id
END

  [sql1, sql2].each do |sql|
    execute_sql(sql)
  end
end


def update_hipaa_code_master
  sql1=<<END
insert into hipaa_codes ( hipaa_adjustment_code)
select distinct(ansi_reason_code) from temp_reason_codes_mapping where ansi_reason_code 
not in (select hipaa_adjustment_code from hipaa_codes)
END
  sql2=<<END
update hipaa_codes set hipaa_code_description='TBD',created_at=NOW(),
 updated_at=NOW(), active_indicator='true' where hipaa_code_description is null
END
  sql3=<<END
delete from hipaa_codes where hipaa_adjustment_code = ''
END

  [sql1, sql2,sql3].each do |sql|
    execute_sql(sql)
  end

end

def update_hipaa_code_id
  sql =<<END
  update temp_reason_codes_mapping trcm, hipaa_codes hc 
set trcm.hipaa_code_id = hc.id
where trcm.ansi_reason_code = hc.hipaa_adjustment_code
END
  execute_sql(sql)
end


def update_client_id
  sql=<<END
  update temp_reason_codes_mapping trcm, clients c
set trcm.client_id = c.id
where trcm.group_code = c.group_code
END
  execute_sql(sql)
end

def update_facility_id
  sql=<<END
update temp_reason_codes_mapping trcm, facilities f
set trcm.facility_id = f.id
where trcm.site_no = f.sitecode
END
  execute_sql(sql)
end

def update_client_code_id
  sql=<<END
update temp_reason_codes_mapping trcm, client_codes cc
set trcm.client_code_id = cc.id
where trcm.client_system_code = cc.adjustment_code
and trcm.group_code = cc.group_code
END
  execute_sql(sql)
end


def populate_reason_codes_facilities_payers

  ['GLOBAL','GROUP','SITE'].each do |map_level|
    sql=<<END
insert into reason_codes_clients_facilities_set_names (reason_code_id,client_id,facility_id,payer_id,created_at,updated_at,
code_status,claim_status_code,denied_claim_status_code,reporting_activity1,reporting_activity2,active_indicator,
source) select reason_code_id,NULL,NULL,payer_id,now(), now(),'ACCEPT',claim_status_code, denied_claim_status_code,  reporting_activity_1_tx,reporting_activity_2_tx,active,'AP' from temp_reason_codes_mapping where map_level = '#{map_level}'
END
    execute_sql(sql)
  end
end


def populate_reason_codes_clients_facilities_set_names_id
  ['GLOBAL','GROUP','SITE'].each do |map_level|
    sql=<<END
  update temp_reason_codes_mapping trcm 
inner join reason_codes_clients_facilities_set_names rccfp using (reason_code_id,client_id,payer_id)
set trcm.reason_code_payer_id=rccfp.id
where trcm.map_level='#{map_level}'
and rccfp.client_id is not null
and rccfp.facility_id is null
and trcm.client_id = rccfp.client_id
and trcm.payer_id = rccfp.payer_id
END
    execute_sql(sql)
  end
end


def populate_reason_codes_clients_facilities_set_names_client_codes
  sql1=<<END
  insert into reason_codes_clients_facilities_set_names_client_codes
(reason_codes_clients_facilities_set_name_id, client_code_id, created_at,updated_at,category)
select reason_code_payer_id,client_code_id,now(), now(),NULL from temp_reason_codes_mapping
where length(client_system_code) >0
END
  sql2=<<END
insert into reason_codes_clients_facilities_set_names_client_codes
(reason_codes_clients_facilities_set_name_id, client_code_id, created_at,updated_at,category)
select reason_code_payer_id,client_code_id,now(), now(),'Denied' from temp_reason_codes_mapping
where length(denied_client_system_code) >0
END

  [sql1,sql2].each do |sql|
    execute_sql(sql)
  end
end


def populate_reason_codes_clients_facilities_set_names_hipaa_codes
  sql1=<<END
insert into reason_codes_clients_facilities_set_names_hipaa_codes
(reason_codes_clients_facilities_set_name_id, hipaa_code_id, created_at,updated_at,category)
select reason_code_payer_id,hipaa_code_id,now(), now(),NULL from temp_reason_codes_mapping
where length(ansi_reason_code) >0
END
  sql2=<<END
insert into reason_codes_clients_facilities_set_names_hipaa_codes
(reason_codes_clients_facilities_set_name_id, hipaa_code_id, created_at,updated_at,category)
select reason_code_payer_id,client_code_id,now(), now(),'Denied' from temp_reason_codes_mapping
where length(denied_ansi_reason_code) >0
END

  [sql1,sql2].each do |sql|
    execute_sql(sql)
  end
end

def populate_facility_lockbox_mapping
  sql=<<END
insert into facility_lockbox_mappings (facility_id,lockbox_number,lockbox_name,lockbox_code,created_at,updated_at)
select f.id, tl.lockbox_number, tl.lockbox_location_name ,tl.lockbox_location_code,now(),now()
from temp_lockbox tl inner join facilities f using(sitecode)
where f.sitecode = tl.sitecode
END
  execute_sql(sql)
end


def make_bac_as_partner
  p = Partner.find_by_name("REVENUE MED")
  if p
    p.name = "BAC"
    p.save(:validate => false)
    sql = "Update clients set partner_id='#{p.id}'"
    execute_sql(sql)
  end
end

def remove_temp_tables
  ['temp_lockbox','temp_payer','temp_reason_codes','temp_reason_codes_mapping'].each do |tbl|
    sql = 'DROP table #{tbl}'
    execute_sql(sql)
  end
end

def execute_sql sql
  puts "=======================================Executing sql ================================\n"
  puts sql
  a = Time.now
  result = ActiveRecord::Base.connection.execute(sql)
  b = Time.now
  puts "\n================Executed in #{(b-a).to_s} seconds====================================\n"
  result
end



def log_errors_while_mapping where, count
  puts where + " : " + count.to_s + " : Errors While inserting to db \n"  
end
