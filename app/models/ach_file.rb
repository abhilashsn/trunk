require 'digest/sha1'

class AchFile < ActiveRecord::Base
  has_many :cr_transactions

  def self.parse_file_info(file_name, file_location)
    file_size = File.size(file_location)
    file_arrival_date = File.mtime(file_location).strftime("%m/%d/%Y")
    file_arrival_time = File.mtime(file_location).strftime("%H:%M:%S")
    file_creation_date = ""
    file_creation_time = ""

    #Sanity checking
    line_count = 1
    file_sample = ""

    File.open(file_location).each do |line|
      break if line_count > 5

      if line[0].strip.to_i == 1
      file_creation_date = line[23..28].strip
      file_creation_time = line[29..32].strip
      line.slice!(23..32)
      end

      file_sample << line

      line_count += 1
    end

    file_hash = hash_string(file_sample)

    fileinfo_match = self.find_by_file_name_and_file_size_and_file_creation_date_and_file_creation_time(file_name, file_size, file_creation_date, file_creation_time)
    filehash_match = self.find_by_file_hash(file_hash)

    if fileinfo_match
      RevremitMailer.notify_duplicate(file_name, file_creation_date, file_creation_time, file_location, fileinfo_match.file_name, "fileinfo").deliver
    elsif filehash_match
      RevremitMailer.notify_duplicate(file_name, file_creation_date, file_creation_time, file_location, filehash_match.file_name, "filehash").deliver
    else
      achfile = self.create(file_name: file_name,
                            file_size: file_size,
                            file_creation_date: file_creation_date,
                            file_creation_time: file_creation_time,
                            file_hash: file_hash,
                            file_arrival_date: file_arrival_date,
                            file_arrival_time: file_arrival_time)
      parse_cr_transactions(achfile.id, file_location)
      achfile.update_attributes(file_load_start_time: achfile.created_at, file_load_end_time: achfile.cr_transactions.last.created_at)
    end
  end

  #Parsing transactions
  def self.parse_cr_transactions(file_id, file_location)
    company_id = nil
    payer_name = nil
    batch_number = nil
    eft_payment_amount = nil
    eft_date = nil
    payment_format_code = nil
    aba_dda_lookup_id = nil
    receivers_name = nil
    eft_payment_amount = nil
    eft_trace_number_ed = nil
    eft_trace_number_eda = nil
    status = nil
    prev_type_code = 0
    blacklist_bool = false

    File.open(file_location).each do |line|
      curr_type_code = line[0].strip.to_i

      #Create Record if a new transaction begins and it isn't a black listed ABA_DDA
      if (prev_type_code >= curr_type_code || line[0..93]  == "9"*94) && !blacklist_bool
        crt = CrTransaction.create(aba_dda_lookup_id: aba_dda_lookup_id,
                                   receivers_name: receivers_name,
                                   payer_name: payer_name,
                                   batch_number: batch_number,
                                   eft_payment_amount: eft_payment_amount,
                                   eft_date: eft_date,
                                   eft_trace_number_ed: eft_trace_number_ed,
                                   eft_trace_number_eda: eft_trace_number_eda,
                                   payment_format_code: payment_format_code,
                                   ach_file_id: file_id,
                                   company_id: company_id,
                                   status: status)
        eft_trace_number_eda = nil
      end

      #Batch Header Record
      if curr_type_code == 5
        company_id = line[40..49].strip
        payer = Payer.find_by_company_id(company_id)
        
        #check to see if link to payer exists
        if !payer
          status = set_status(status, curr_type_code)
        else
          status = nil
        end
        
        payer_name = line[4..19].strip
        batch_number = line[87..93].strip
        eft_date = line[69..74].strip
        payment_format_code = line[50..52].strip
        prev_type_code = curr_type_code
      #Entry Detail Record
      elsif curr_type_code == 6
        receivers_aba_number = line[3..11].strip
        receivers_dda_number = line[12..28].strip
        aba_dda_lookup = AbaDdaLookup.find_by_aba_number_and_dda_number(receivers_aba_number, receivers_dda_number)

        
        #check to see if link to a facility exists 
        if !aba_dda_lookup
          aba_dda_lookup = AbaDdaLookup.create(aba_number: receivers_aba_number, dda_number: receivers_dda_number)
          aba_dda_lookup_id = aba_dda_lookup.id
          status = set_status(status, curr_type_code)
          blacklist_bool = false
        elsif !aba_dda_lookup.facility_id
          aba_dda_lookup_id = aba_dda_lookup.id
          status = set_status(status, curr_type_code)
          blacklist_bool = false
        else
          aba_dda_lookup_id = aba_dda_lookup.id
          blk_lst_facility = Facility.find_by_name("BLACKLISTED")
          #if "blacklisted" facility exists, check to see if facility is blacklisted
          blacklist_bool = blk_lst_facility.nil? ? false : (aba_dda_lookup.facility_id == blk_lst_facility.id) 
        end

        receivers_name = line[54..75].strip
        eft_payment_amount = line[29..38].strip
        eft_trace_number_ed = line[79..93].strip
        prev_type_code = curr_type_code
      #Addenda Record
      elsif curr_type_code == 7 && line[3..5].strip.include?("TRN")
        eft_trace_number_eda = line.split("*")[2]
        prev_type_code = curr_type_code
      end
    end
  end

  #Set status
  def self.set_status(status, type_code)
    case
    when type_code == 5 then
      status = "Unidentified Payer"
    when (type_code == 6 && status == "Unidentified Payer") then
      status = "Both"
    when (type_code == 6 && status == "Both") then 
      status = "Both"
    else
      status = "Unidentified Site"
    end
  end

  def self.hash_string(string)
      Digest::SHA1.hexdigest(string)
  end

end
