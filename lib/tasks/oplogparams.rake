namespace :oplogparams do
  desc "Insert all op log params to lookup field"
  task :load => :environment do
    load_formats
    load_content_options
    load_status_grouping_options
    load_group_options
    load_db_fields
    load_custom_fields
    load_summary_fields
    load_summary_by_options
    load_summary_position
    load_file_name_format
    load_folder_name_format
    load_plb_options
    load_reject_check_options
    load_prefix_options
    load_totaling_options
    puts "done loading all the parameters for operation log..."
  end

  task :load_configs => :environment do
    apply_config_hash
  end  
end


def load_formats
  values = ["csv", "txt", "xls", "xlsx"]
  load_params "format", values
end

def load_content_options
  values = ["check", "eob"]
  load_params "content_layout", values    
end

def load_status_grouping_options
  values = ["All", "Completed Jobs", "Incompleted Jobs"]
  load_params "job_status_grouping", values
end

def load_group_options
  values = ["batch", "batch date", "facility", "payer", "payer (cpid)", "nextgen",
    "client and deposit date"]
  load_params "group_by", values    
end

def load_db_fields
  values = ["835 Amount","Aba Routing Number","Batch ID","Batch Name","Check",
            "Check Amount","Check Date","Check Number","Correspondence",
            "Deposit Date","Eft Amount","Export Date","Facility Name",
            "Harp Source","Image Id","Image Page No","OnBase Name",
            "Patient Account Number","Payer","Payer Account Number",
            "Payer Name","Processed (Y/N)","Page Number","Reason Not Processed",
            "Reject Reason", "Document Classification", "Statement #","Status","Sub Total","Zip File Name",
            "Date Of Service", "Total Charge", "Patient Last Name",
            "Patient Date Of Birth", "Xpeditor Document Number",
            "Patient First Name", "Member Id", "837 File Type",
            "Client Code", "PLB", "Unique Identifier", "Lockbox Id", "MRN",
            "Payee ID", "Service Provider ID", "Payment Trans Code",
            "Payment Method", "Tooth Number", "Transaction Type", "Sequence",
            "Account Type", "Image No"]
  load_params "headers", values    
end


def load_custom_fields
  values = ["5"]
  load_params "custom_header_count", values
end


def load_summary_fields
  values = ["Total Deposit Amount", "Total Accepted Amount", 
    "Total Rejected Amount", "Total 835 Amount", "Total Hospital Amount",
    "Total Physician Amount", "Total Unidentified Amount"]
  load_params "summary_fields", values
end

def load_summary_by_options
  values = ["batch", "batch date"]
  load_params "summarize_by", values
end


def load_summary_position
  values = ["header-left", "header-right","footer-left", "footer-right"]
  load_params "summary_position", values
end

def load_file_name_format
  values = ["Client Id","Batch date(MMDDYY)","Batch date(CCYYMMDD)","Batch date(MMDDCCYY)","Batch date(DDMMYY)","Batch date(YYMMDD)","Batch date(YMMDD)","Batch date(DD_MM_YY)","Batch date(MMDD)","Facility Name abbreviation","Batch Id","3-SITE","Facility Name","Check Number","Payer Name","Cut","EXT","Lockbox Number","Client Name"]
  load_params "file_name_format", values
end

def load_folder_name_format
  values = ["Client Id","Batch date(MMDDYY)","Batch date(CCYYMMDD)","Batch date(MMDDCCYY)","Batch date(DDMMYY)","Batch date(YYMMDD)","Batch date(YMMDD)","Batch date(DD_MM_YY)","Batch date(MMDD)","Facility Name abbreviation","Batch Id","3-SITE","Facility Name","Check Number","Payer Name","Cut","EXT","Lockbox Number","Client Name"]
  load_params "folder_name_format", values
end

def load_plb_options
  values = ["print plb"]
  load_params "print_plb", values
end

def load_reject_check_options
  values = ["print reject check"]
  load_params "print_reject_check", values
end

def load_prefix_options
  values = ["prefix quotes"]
  load_params "prefix_quotes", values
end


def load_totaling_options
  values = ["Batch Total", "Payer Total", "Grand Total", "Deposit Total"]
  load_params "total", values
end

def load_params (name, values)
  values.each do |value|
    hash = {:lookup_type=>"operation_log", "name"=>name, "value"=>value}    
    if !FacilityLookupField.find(:first, :conditions=>hash)
      FacilityLookupField.create(hash)
    end      
  end
end



def apply_config_hash 
  clients =   ["visalia_medical_clinic","peachtree_park_peds","insight_health_corporation","goodman_campbell_brain_and_spine","stanford_university_medical_center","horizon_laboratory_llc", "quadax", "medassets"]
  client = ENV["client"]
  if clients.include?(client)
    yield_fac_conf(eval(client)) do |facilities,hash|
      facilities.each do |name|
        facility = Facility.find_by_name(name.strip)
        config = facility.facility_output_configs.find(:last, :conditions=>"report_type='Operation Log'")
        if config
          config.operation_log_config = hash
          puts "applying hash to facility #{name}\n"
          config.save(:validate => false)
        else
          puts "facility #{name} not found\n"
        end
      end
    end
  else
    message_hf
    puts "Usage: rake oplogparams:load_configs client=client_name"
    puts "please provide a client to set config for, client_name can be any of the following: \n#{clients.join("\n")}"
    message_hf
  end
end



def yield_fac_conf p
  yield p.first, p.last
end

# these are the functions which should giv configs and facilities to config_inserter for different client/db
def visalia_medical_clinic
  config_hash={"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"", "6"=>"Payer Name", "23"=>"", "12"=>"", "7"=>"Status", "24"=>"", "13"=>"", "8"=>"Image Id", "25"=>"", "14"=>"", "9"=>"Reject Reason", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Export Date", "18"=>"", "2"=>"Check", "20"=>"", "19"=>"", "3"=>"Check Number", "21"=>"", "10"=>"", "4"=>"Check Amount", "5"=>"Eft Amount"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Abbr]_[Batch Id]_operation_log"}
  facilities = ["VISALIA MEDICAL CLINIC"]
  [facilities, config_hash]
end


def peachtree_park_peds
  config_hash = {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"", "6"=>"Payer Name", "23"=>"", "12"=>"", "7"=>"Status", "24"=>"", "13"=>"", "8"=>"Image Id", "25"=>"", "14"=>"", "9"=>"Reject Reason", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Export Date", "18"=>"", "2"=>"Check", "20"=>"", "19"=>"", "3"=>"Check Number", "21"=>"", "10"=>"", "4"=>"Check Amount", "5"=>"Eft Amount"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Abbr]_OPERATION_LOG"}
  facilities = ["PEACHTREE PARK PEDS"]   
  [facilities, config_hash]
end


def insight_health_corporation
  config_hash=     {"summary_field_label"=>{"0"=>"", "1"=>"Total Accepted Amount", "2"=>"Total Rejected Amount"}, "group_by"=>{"0"=>"batch", "1"=>"payer", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"Total Deposit Amount", "1"=>"Total Accepted", "2"=>"Total Rejected"}, "oplogformat"=>"xls", "prefix_quotes"=>"prefix quotes", "total"=>{"0"=>"Batch Total", "1"=>"Payer Total", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"Image Id", "6"=>"Check Amount", "23"=>"", "12"=>"Zip File Name", "7"=>"Sub Total", "24"=>"", "13"=>"Reject Reason", "8"=>"Eft Amount", "25"=>"", "14"=>"", "9"=>"Payer Name", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Deposit Date", "18"=>"", "2"=>"Export Date", "20"=>"", "19"=>"", "3"=>"Check", "21"=>"", "10"=>"Status", "4"=>"Check Number", "5"=>"Check Date"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"Telco", "3"=>"", "4"=>""}, "summary_position"=>"header", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Abbr]_Operation_Log"}

  facilities = ["INSIGHT HEALTH CORP","INSIGHT HEALTH CORPORATION","MAXUM HEALTH SERVICES CORP", "INSIGHT PREMIER HEALTH LLC", "OCEAN MEDICAL IMAGING",
                "SURGICAL SPECIALITY IMAGING LLC", "MAINE MOLECULAR IMAGING LLC", "IMAGE GUIDED PAIN MANAGEMENT PC","WILLOWBEND DIAGNOSTIC IMAGING"] 
  [facilities, config_hash]
end

def goodman_campbell_brain_and_spine
  config_hash =  {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch date", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"Batch Total", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"Reject Reason", "6"=>"Eft Amount", "23"=>"", "12"=>"", "7"=>"835 Amount", "24"=>"", "13"=>"", "8"=>"Payer Name", "25"=>"", "14"=>"", "9"=>"Status", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Deposit Date", "18"=>"", "2"=>"Check", "20"=>"", "19"=>"", "3"=>"Check Number", "21"=>"", "10"=>"Image Id", "4"=>"Check Date", "5"=>"Check Amount"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Batch date(YYMMDD)]_GCBS_Operation_log"}
  facilities = ["GOODMAN CAMPBELL BRAIN AND SPINE"]
  [facilities, config_hash]
end


def stanford_university_medical_center
  config_hash = {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"Batch Total", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"", "6"=>"Payer Name", "23"=>"", "12"=>"", "7"=>"Status", "24"=>"", "13"=>"", "8"=>"Image Id", "25"=>"", "14"=>"", "9"=>"Reject Reason", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Export Date", "18"=>"", "2"=>"Check", "20"=>"", "19"=>"", "3"=>"Check Number", "21"=>"", "10"=>"", "4"=>"Check Amount", "5"=>"Eft Amount"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Abbr]_[Batch Id]_operation_log"}
  facilities = ["STANFORD UNIVERSITY MEDICAL CENTER"]  
  [facilities, config_hash]
end


def horizon_laboratory_llc
  config_hash = {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch date", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Abbr]_Operation_log"}  
  facilities = ["HORIZON LABORATORY LLC"]
  [facilities, config_hash]
end

def quadax
  config_hash =     {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"Total Deposit Amount", "1"=>"Total Accepted Amount", "2"=>"Total Rejected Amount"}, "oplogformat"=>"csv", "prefix_quotes"=>"", "total"=>{"0"=>"Batch Total", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"Payer Name", "6"=>"Check Number", "23"=>"", "12"=>"Status", "7"=>"Check Date", "24"=>"", "13"=>"Image Id", "8"=>"Patient Account Number", "25"=>"", "14"=>"Zip File Name", "9"=>"Image Page No", "26"=>"", "15"=>"Reject Reason", "27"=>"", "16"=>"OnBase Name", "0"=>"Batch Name", "28"=>"", "17"=>"Correspondence", "1"=>"Deposit Date", "18"=>"Statement #", "2"=>"Export Date", "20"=>"835 Amount", "19"=>"Harp Source", "3"=>"Check", "21"=>"", "10"=>"Check Amount", "4"=>"Aba Routing Number", "5"=>"Payer Account Number"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"eob", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"footer", "file_name_format"=>"[Batch date(YYMMDD)]_[Facility Abbr]_Operation_Log"}
  
  facilities= ["PATHOLOGY MEDICAL SERVICES","STANFORD UNIVERSITY MEDICAL CENTER","HORIZON LABORATORY LLC","CARIS MOLECULAR PROFILING INSTITUTE","CARIS DIAGNOSTICS",
               "METROPLEX PATHOLOGY ASOC", "COHEN DERMATOPATHOLOGY","CARIS DIAGNOSTICS-DO"]
  [facilities, config_hash]
end


def medassets
  config_hash = {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>""}, "group_by"=>{"0"=>"batch date", "1"=>"", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"Batch Total", "1"=>"", "2"=>"", "3"=>""}, "header"=>{"22"=>"", "11"=>"", "6"=>"Status", "23"=>"", "12"=>"", "7"=>"Reject Reason", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"Batch Name", "28"=>"", "17"=>"", "1"=>"Check Number", "18"=>"", "2"=>"Check Date", "20"=>"", "19"=>"", "3"=>"Check Amount", "21"=>"", "10"=>"", "4"=>"835 Amount", "5"=>"Payer Name"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>""}, "summary_position"=>"", "file_name_format"=>"[Batch date(YYMMDD)]_operation_log"}
  facilities = ["Richmond University Medical Center", "Merit Mountainside"]
  [facilities, config_hash]
end

def message_hf
  puts "\n****************************************************\n"
end
