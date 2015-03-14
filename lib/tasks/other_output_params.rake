namespace :other_output_params do 
  desc "Insert all other outputs parameter to the lookup table"
  
  task :load => :environment do
    load_other_output_types
    load_headers_A37
    load_formats_A37
    load_group_options_A37
    load_file_name_format_A37
    load_zip_name_format_A37
    load_headers_A36
    load_formats_A36
    load_group_options_A36
    load_headers_A36
    load_file_name_format_A36
    load_zip_name_format_A36
  end  

  task :tester => :environment do
    OtherOutput::Generator.new(622).generate
  end
  
end


def load_other_output_types
  values = ["A37 Report", "A36 Report", "Human Readable Eob"]
  load_params2 "ReportType", values
end

def load_headers_A37
  values = ["Bank Acct Number","Bank Routing Number","Batch Id","Captured Provider Adjustments","Carrier Code or Insurance Plan","Check Batch Date","Check Number","Claim Coins Amt.","Claim Deductible Amt.","Claim Payment Amt.","Client Data File","Financial Class","HCPCS Code","HLSC CHECK Number","HLSC GATEWAY","HLSC PAYER ID","Image Reference Number","Invoice Number","Line Total Charge","Line Total Payment","LOCKBOX BATCH CUT","LOCKBOX BATCH ID","Lockbox Number","Patient Control Number","Patient First Name","Patient Last Name","Patient Number","Payer Name","Provider Adjustment","Service Date","Source File","Thru Date","Transmit Date","Reason Code", "Dummy"]
  load_params2 "headers", values, "A37 Report"
end

def load_formats_A37
  values = ["csv","xml"]
  load_params2 "format", values, "A37 Report"
end

def load_group_options_A37
  values = ["batch","batch date", "cut"]
  load_params2 "group by", values, "A37 Report"
end

def load_file_name_format_A37
  values = ["Batch date(YMMDD)","Batch date(MMDD)","NNN","Cut","3-SITE","Lockbox Number", "EXT"]
  load_params2 "file_name_format", values, "A37 Report"
end

def load_zip_name_format_A37
  values = ["Batch date(YMMDD)","Batch date(MMDD)","NNN","Cut","3-SITE","Lockbox Number"]
  load_params2 "zip_name_format", values, "A37 Report"
end


def load_headers_A36
  values = ["ABA Routing Number","Batch Date","Batch ID","Batch Time","Batch Total Payment Amount","Batch Type","Check Account Number","Check Number","HIC #","HCPCS Code","Image Type","Line Allowed Amount","Line Coinsurance Amount","Line Contractual Amount","Line Deductible Amount","Line Denied Amount","Line Non-Covered Charge","Line Payment Amount","Line Primary Payor Payment Amount","Line Service Date","Line Total Charge","Lockbox #","Patient Control Number","Patient Name","Payer Name","Payer Proprietary Adjustment Reason Code","Reason Code","Raw TIF Image File Name","Source Batch File Name","Trace Number", "Dummy"]
  load_params2 "headers", values, "A36 Report"    
end


def load_formats_A36
  values = ["csv","xml"]
  load_params2 "format", values, "A36 Report"
end

def load_group_options_A36
  values = ["batch","batch date", "cut"]
  load_params2 "group by", values, "A36 Report"
end


def load_file_name_format_A36
  values = ["Batch date(YMMDD)","Batch date(MMDD)","NNN","Cut","3-SITE","Lockbox Number"]
  load_params2 "file_name_format", values, "A36 Report"
end


def load_zip_name_format_A36
  values = ["Batch date(YMMDD)","Batch date(MMDD)","NNN","Cut","3-SITE","Lockbox Number"]
  load_params2 "zip_name_format", values, "A36 Report"
end


def load_params2 name, values, category=nil
  values.each do |value|
    hash = {:lookup_type => "other_output", "name" => name, "value" => value, "category" => category}
    if !FacilityLookupField.find(:first, :conditions=>hash)
      FacilityLookupField.create(hash)
    end      
  end
  hash = {:lookup_type => "other_output","name" => name, "category" => category}
  current_values = FacilityLookupField.find(:all, :conditions => hash).collect(&:value)
  (current_values - values).each do |value|
    puts value
    FacilityLookupField.find(:all, :conditions => hash.merge({"value" => value})).each do |lookup|
      lookup.destroy
    end
  end  
end
