class OperationLog::Document
  attr_reader :check, :eob, :facility, :micr,  :config, :batch, :job, :client
  include Output835Helper
  include OperationLogHelper
  def initialize(pivot_batch_id, config)
    @pivot_batch_id = pivot_batch_id[0]
    @config = config
    @batch = Batch.find(@pivot_batch_id)
    @facility = @batch.facility
    @client = @facility.client
    @delimiter = ","
    @delimiter = "\t" if @config.format=="xls" || @config.format=="xlsx"
    @total_check_amount = 0
    @total_eft_amount = 0
    @total_835_amount = 0
    @total_client_check_amount = 0
    @total_client_eft_amount = 0
    @total_client_835_amount = 0
    @total_hospital_amount = 0
    @total_physician_amount = 0
  end

  def generate
    doc_string = ""
    if !@config.for_facility
      @batches = get_batch_ids(@client, @config, @pivot_batch_id)
      if @client.name.upcase.gsub("'", "") == 'CHILDRENS HOSPITAL OF ORANGE COUNTY'
        grouper do
          set_account_type
        end
      end
      if @client.name.upcase == 'MEDASSETS'  or @client.name.upcase == "BARNABAS"
        grouper do
          set_actual_account_number
        end
      end
      doc_string << total_summary  if @config.summary_position.starts_with?("header")
      doc_string << header_row
      doc_string << column_rows
      doc_string << grand_and_deposit_summary
      doc_string << total_summary  if @config.summary_position.starts_with?("footer")      
    else
      client = Batch.find(@pivot_batch_id).facility.client
      client.facilities.each do |facil|                
        @facility = facil
        @batches = Batch.by_batch_date_and_facility(Batch.find(@pivot_batch_id), facil)
        if @batches.size > 0
          doc_string << total_summary  if @config.summary_position.starts_with?("header")
          doc_string << header_row
          doc_string << column_rows
          doc_string << total_summary  if @config.summary_position.starts_with?("footer")          
          @total_client_check_amount = @total_client_check_amount + @total_check_amount
          @total_client_eft_amount = @total_client_eft_amount + @total_eft_amount
          @total_client_835_amount = @total_client_835_amount + @total_835_amount
          @total_check_amount = 0
          @total_eft_amount = 0
          @total_835_amount = 0
        end
      end
      doc_string << grand_and_deposit_summary
    end
    return doc_string        
  end

  def set_account_type
    unless @checks.blank?
      @checks.each_with_index do |chk,index|
        chk_id_array = []
        eob_id_array = []
        acc_num_array = []
        eob_class_array = []
        eob_brtype_array = []
        acc_type_array = []

        all_eobs = get_all_eobs(chk)

        begin
          all_eobs.each do |eob|
            if eob.class == InsurancePaymentEob
              @check_info_id = eob.check_information_id
              chk_id_array << eob.check_information_id
              eob_brtype_array << eob.balance_record_type
            else
              chk_id_array << @check_info_id
              eob_brtype_array << ''
            end
            acc_num_array << eob.patient_account_number
            eob_class_array << eob.class.to_s
            eob_id_array << eob.id
          end

          acc_num_array.each_with_index do |acc_num, index|
            if acc_num != "NOACCOUNT" and !acc_num.match(/^[0]*$/) and (eob_brtype_array[index] == nil or eob_brtype_array[index] == '')
              index_of_physician_claim = acc_num.upcase.index("CS")
              index_of_hospital_claim_start_with_p = acc_num.upcase.index("P")
              index_of_hospital_claim_start_with_y = acc_num.upcase.index("Y")
              numeric_hospital_claim = (acc_num.match(/^[0-9]*$/) &&
                  acc_num.length >= 9)

              if index_of_physician_claim && index_of_physician_claim == 0
                account_type_value = "PHYSICIAN"
              elsif (index_of_hospital_claim_start_with_p && index_of_hospital_claim_start_with_p == 0) ||
                  (index_of_hospital_claim_start_with_y && index_of_hospital_claim_start_with_y == 0) ||
                  (numeric_hospital_claim)
                account_type_value = "HOSPITAL"
              else
                account_type_value = "UNIDENTIFIED"
              end

            unless eob_class_array[index] == "ProviderAdjustment"
              acc_type_array << account_type_value
            end

              if eob_class_array[index]== "ProviderAdjustment"
                actual_eob = ProviderAdjustment.find_by_id(eob_id_array[index])
              else
                actual_eob = InsurancePaymentEob.find_by_id(eob_id_array[index])
              end
              actual_eob.account_type = account_type_value
              actual_eob.save
            end
          end

          acc_num_array.each_with_index do |acc_num, index|
          index_of_physician_claim = acc_num.upcase.index("CS")
          index_of_hospital_claim_start_with_p = acc_num.upcase.index("P")
          index_of_hospital_claim_start_with_y = acc_num.upcase.index("Y")
          numeric_hospital_claim = (acc_num.match(/^[0-9]*$/) &&
              acc_num.length >= 9)
          plb_unidentified_condn = ((eob_class_array[index] == "ProviderAdjustment") and
            (!(index_of_physician_claim and index_of_physician_claim == 0) and
             !(index_of_hospital_claim_start_with_p and index_of_hospital_claim_start_with_p == 0) and
             !(index_of_hospital_claim_start_with_y and index_of_hospital_claim_start_with_y == 0) and
             !(numeric_hospital_claim)))
          if plb_unidentified_condn == true or acc_num == "NOACCOUNT" or acc_num.match(/^[0]*$/)!= nil or (eob_brtype_array[index] != nil and eob_brtype_array[index] != '')
              acc_type_array_uniq = acc_type_array.uniq
              if acc_type_array_uniq.length == 1
                if eob_class_array[index]== "ProviderAdjustment"
                  actual_eob = ProviderAdjustment.find_by_id(eob_id_array[index])
                else
                  actual_eob = InsurancePaymentEob.find_by_id(eob_id_array[index])
                end
                actual_eob.account_type = acc_type_array_uniq[0]
                actual_eob.save
              else
                if eob_class_array[index]== "ProviderAdjustment"
                  actual_eob = ProviderAdjustment.find_by_id(eob_id_array[index])
                else
                  actual_eob = InsurancePaymentEob.find_by_id(eob_id_array[index])
                end
                actual_eob.account_type = "UNIDENTIFIED"
                actual_eob.save
              end
            end
          end

        rescue Exception => e
          Output835.oplog_log.error e.message
          Output835.oplog_log.error e.backtrace.join("\n")
        end
      end
    end
  end

  def set_actual_account_number
    unidentified_acc_no_of_facility = @facility.unidentified_account_number
    unless @checks.blank?
      @checks.each_with_index do |chk,index|
        all_eobs = get_all_eobs(chk)
        account_nos = all_eobs.collect(&:patient_account_number)
        acc_num_str = []
        begin
          all_eobs.each do |eob|
            if !unidentified_acc_no_of_facility.blank? && unidentified_acc_no_of_facility.include?(eob.patient_account_number)
              actual_acc_num = ""
            else
              actual_acc_num = get_exact_account_number(eob, acc_num_str, account_nos)
            end
            eob.account_type = actual_acc_num
            eob.save
          end
        rescue Exception => e
          Output835.oplog_log.error e.message
          Output835.oplog_log.error e.backtrace.join("\n")
        end
      end
    end
  end

  def get_all_eobs(chk)
    Output835.oplog_log.info "Check information id: #{chk.id}"
    Output835.oplog_log.info "Check Number: #{chk.check_number}"
    eobs = chk.insurance_payment_eobs
    Output835.oplog_log.info "Check has #{eobs.length} eobs"
    all_eobs = []
    if @config.print_plb == "print plb"
      provider_adjustments = chk.job.get_all_provider_adjustments
      eobs.each do |eob|
        all_eobs << eob
        if !(eob.claim_interest.to_f.zero?) and @facility.details[:interest_in_service_line].blank?
          all_eobs << eob
        end
      end
      if !provider_adjustments.blank?
        all_eobs = all_eobs + provider_adjustments
      else
        all_eobs = all_eobs
      end

    else
      all_eobs = eobs
    end
  end

  private
  
  include(DataFetcherCheck)
    
  def header_row
    @headers = ""
    @headers <<  @config.header_fields.map{|j| j[1].present? ? (j[1] == "NOLABEL" ? "" : j[1] ) : j[0]}.compact.join(@delimiter)  
    @headers <<  (@config.custom_header_fields.present? ? (@delimiter + @config.custom_header_fields.join(@delimiter)) : "" )
  end
  
  def column_rows
    Output835.oplog_log.info "Content Layout: #{@config.content_layout}"
    if @config.content_layout == "eob"
      extend(OperationLog::DataFetcherEob)
      extend(OperationLog::DataFetcherEobWithPlb)
      extend(OperationLog::DataFetcherEobWithExtraPlb)
      extend("OperationLog::#{facility.client.name.downcase.gsub("'", "").gsub(" ", "_").classify}Eob".constantize) rescue nil
      extend("OperationLog::#{facility.name.downcase.gsub("'", "").gsub("-", "_").gsub(" ", "_").classify}Eob".constantize) rescue nil
      extend("OperationLog::#{facility.client.name.downcase.gsub("'", "").gsub(" ", "_").classify}EobWithPlb".constantize) rescue nil
      extend("OperationLog::#{facility.name.downcase.gsub("'", "").gsub("-", "_").gsub(" ", "_").classify}EobWithPlb".constantize) rescue nil
      extend("OperationLog::#{facility.client.name.downcase.gsub("'", "").gsub(" ", "_").classify}EobWithExtraPlb".constantize) rescue nil
      extend("OperationLog::#{facility.name.downcase.gsub("'", "").gsub(" ", "_").classify}EobWithExtraPlb".constantize) rescue nil
    end
    
    if @config.content_layout == "check"
      extend("OperationLog::#{facility.client.name.downcase.gsub(" ", "_").classify}Check".constantize) rescue nil
      extend("OperationLog::#{facility.name.downcase.gsub(" ", "_").classify}Check".constantize) rescue nil
    end
    
    row_string = ""
    @counter = 0
    grouper do
      unless @checks.blank?
        case @config.content_layout
        when "eob"

          @checks.each_with_index do |chk,index|
            @index = @counter
            @check = chk
            @job = @check.job
            @micr = chk.micr_line_information

            #This is special requirement from BNY client CHOC
            #Although the content layout is 'eob' , this client want to see the rejected
            #check details also in operation log which do no have any eobs.
            if @config.print_reject_check == "print reject check"
              if chk.job.job_status  == JobStatus::INCOMPLETED
                row_string << evaluate_row_from_headers("chk")
                @total_hospital_amount = @total_hospital_amount
                @total_physician_amount = @total_physician_amount
              end
            end
            all_eobs = get_all_eobs(chk)
            
            begin
              eob_id_array = []
              all_eobs.sort_by { |a|
                Output835.oplog_log.info "This is a #{a.class.to_s} Record"
                Output835.oplog_log.info "Eob id: #{a.id}"
                Output835.oplog_log.info "Patient Account Number of EOB : #{a.patient_account_number}"
                Output835.oplog_log.info "Eob's Image page Number : #{a.image_page_no}"
                @prev_eob_id = 0
                [ a.image_page_no, a.class.to_s ]}.each do |eob|
                @eob = eob
                
                if eob.class == ProviderAdjustment
                  row_string << evaluate_row_from_headers("plb")
                else
                  if @config.print_plb == "print plb"
                    if eob_id_array.blank? || !eob_id_array.include?(eob.id)
                      row_string << evaluate_row_from_headers("eob")
                    else
                      row_string << evaluate_row_from_headers("extra plb")
                    end
                  else
                    row_string << evaluate_row_from_headers("eob")
                  end
                end
                eob_id_array << eob.id

                if chk.job.job_status  == JobStatus::COMPLETED
                  if eob.class == InsurancePaymentEob
                    @total_physician_amount += eob.total_amount_paid_for_claim.to_f  if eob.account_type == "PHYSICIAN"
                    @total_hospital_amount += eob.total_amount_paid_for_claim.to_f  if eob.account_type == "HOSPITAL"
                  else
                    @total_physician_amount += eob.amount.to_f if eob.account_type == "PHYSICIAN"
                    @total_hospital_amount += eob.amount.to_f if eob.account_type == "HOSPITAL"
                  end
                end
              end
              @counter = @counter + 1

            rescue Exception => e
              Output835.oplog_log.error e.message
              Output835.oplog_log.error e.backtrace.join("\n")
            end
          end

        when "check"
          @counter = 0
          @checks.each_with_index do |chk,index|
            Output835.oplog_log.info "Check information id: #{chk.id}"
            Output835.oplog_log.info "Check Number: #{chk.check_number}"
            #@index = index
            @index = @counter
            @check = chk
            @job = @check.job
            @micr = chk.micr_line_information
            row_string << evaluate_row_from_headers("check")
            @counter = @counter + 1
          end
        else
        end
        row_string << summerize_groups
      end
    end
    return row_string
  end

  def segregate_checks(checks)
    nextgen_checks = []
    old_checks = []
    nextgen_grid_checks = []
    rejected_checks = []
    patpay_checks = []

    insurance_checks = checks.select do |check|
      check.payer && check.job.payer_group != "PatPay" &&
        check.job.job_status != JobStatus::INCOMPLETED
    end

    nextgen_checks = insurance_checks.select do |check|
      eobs = check.insurance_payment_eobs
      eobs.any?{|eob| !eob.old_eob_of_goodman?}
    end

    old_checks = insurance_checks.select do |check|
      eobs = check.insurance_payment_eobs
      eobs.any?{|eob| eob.old_eob_of_goodman?}
    end

    patpay_checks =  checks.select do |check|
      check.payer && check.job.payer_group == 'PatPay'
    end

    nextgen_grid_checks = checks.select do |check|
      nextgen_check?(check)
    end

    rejected_checks =  checks.select do |check|
      rejected_check?(check)
    end
   
    [nextgen_checks, old_checks, patpay_checks, nextgen_grid_checks, rejected_checks]
  end

  def payer_type(check)
    begin
      if rejected_check?(check) && config.by_nextgen
        "rejected"
      elsif nextgen_check?(check)
        "queue_nextgen"
      elsif check.payer && check.job.payer_group == 'PatPay'
        "patpay"
      elsif check.payer && check.job.payer_group != 'PatPay'
        insurance_payid(check)
      end
    rescue Exception => e
      Output835.oplog_log.info "Payer is missing for check number : #{check.check_number}, id : #{check.id}"
      Output835.oplog_log.error e.message
    end
  end

  def insurance_payid check
    payer = check.payer
    if payer
      group_name = (@nextgen_insurance ? "queue_goodman_nextgen_#{payer.output_payid(@facility)}" : "actual_insurance_#{payer.output_payid(@facility)}")
    end
  end

  def split_by_ten_checks(sorted_array, key)
    sorted_array.each do |single_grouped_array|
      sub_grp_index = 0
      sub_group_size = 10
      group_index = 0
      group_check_length = single_grouped_array.length
      balance_checks = group_check_length % sub_group_size
      number_of_sub_grps = (balance_checks == 0)? (group_check_length / sub_group_size): ((group_check_length / sub_group_size) + 1)
      sub_grp_number = 0
      while(sub_grp_number < number_of_sub_grps)
        splitted_checks = single_grouped_array[sub_grp_index, sub_group_size]
        @checks_array << splitted_checks
        @sorted_checks_hash[key] << splitted_checks
        @counter = 0
        unless splitted_checks.blank?
          sub_grp_number += 1
          sub_grp_index = sub_group_size * sub_grp_number
          group_index += 1 if sub_grp_number > 1
        end
        @sub_grp_indx_hash[key] << group_index
      end
    end
  end

  #this method should do the grouping and then yield for further processing
  def grouper
    @generate_batch_summary = false

    if ((@config.primary_group == "payer" && @config.without_batch_grouping) ||
          @config.by_nextgen)
      @all_checks = get_operation_log_checks(@config.job_status_grouping, @batches.collect(&:id))
      
      if @config.primary_group == "payer" && @config.without_batch_grouping
        chk_grps = @all_checks.group_by{|b| get_payer_criteria(b).to_s}
      elsif @config.by_nextgen
        Output835.oplog_log.info "Grouping is By NextGen"
        groups = segregate_checks(@all_checks)
        chk_grps = {}
        
        groups.each_with_index do |checks, index|
          @nextgen_insurance = (index == 0)
          if index == 0
            chk_grps = (checks.group_by{|check| payer_type(check).to_s})
          else
            chk_grps.merge!(checks.group_by{|check| payer_type(check).to_s})
          end
        end
      end

      group_keys = chk_grps.keys
      ideal_insurance = {}
      patpay = {}
      nextgen_insurance = {}
      nextgen_patpay = {}
      rejected = {}

      ideal_insurance = chk_grps.select {| key, value | key.include?("actual_insurance")}
      patpay = chk_grps.select {| key, value | key.include?("patpay")}
      nextgen_insurance = chk_grps.select {| key, value | key.include?("queue_goodman_nextgen")}
      nextgen_patpay = chk_grps.select {| key, value | key.include?("queue_nextgen")}
      rejected = chk_grps.select {| key, value | key.include?("rejected")}
        
      ideal_insurance_sorted = ideal_insurance.sort_by{|key,value| payer_name_for_check(value.first)}
      nextgen_insurance_sorted = nextgen_insurance.sort_by{|key,value| payer_name_for_check(value.first)}

      ideal_insu_sorted_array = []
      patpay_array = []
      nextgen_insu_sorted_array = []
      nextgen_patpay_array = []
      rejected_array = []
      for i in 0..ideal_insurance_sorted.length - 1
        for j in 1..ideal_insurance_sorted[0].length - 1
          ideal_insu_sorted_array << ideal_insurance_sorted[i][j]
        end
      end

      for k in 0..nextgen_insurance_sorted.length - 1
        for l in 1..nextgen_insurance_sorted[0].length - 1
          nextgen_insu_sorted_array << nextgen_insurance_sorted[k][l]
        end
      end
      patpay_array = patpay.values
      nextgen_patpay_array = nextgen_patpay.values
      rejected_array = rejected.values

      if config.by_cpid || config.by_nextgen
        @checks_array = []
        @sub_grp_indx_hash = Hash.new{|h, k| h[k] = []}
        @sorted_checks_hash = Hash.new{|h, k| h[k] = []}

        if !ideal_insu_sorted_array.blank?
          split_by_ten_checks(ideal_insu_sorted_array, 'ideal_insurance')
        end

        if !patpay_array.blank?
          split_by_ten_checks(patpay_array, 'patpay')
        end

        if !nextgen_insu_sorted_array.blank?
          split_by_ten_checks(nextgen_insu_sorted_array, 'nextgen_insurance')
        end

        if !nextgen_patpay_array.blank?
          key = 'nextgen_patpay'
          @checks_array << nextgen_patpay_array.flatten
          @sub_grp_indx_hash[key] << 0
          @sorted_checks_hash[key] << nextgen_patpay_array.flatten

        end
        if !rejected_array.blank?
          key = 'rejected'
          @checks_array << rejected_array.flatten
          @sub_grp_indx_hash[key] << 0
          @sorted_checks_hash[key] << rejected_array.flatten
        end

        ordered_group_keys = @sorted_checks_hash.keys
        
        ordered_group_keys.each do |group_key|
          
          @nextgen_patpay = false
          @nextgen_insurance = false
          @ideal_patpay = false
          @ideal_insurance = false
          @rejected = false
          
          group_checks = @sorted_checks_hash[group_key]
          sub_grp_indx_ary = @sub_grp_indx_hash[group_key]
          @nextgen_patpay = group_key.include?("nextgen_patpay")
          @nextgen_insurance = group_key.include?("nextgen_insurance")
          @ideal_patpay = group_key.include?("patpay")
          @ideal_insurance = group_key.include?("ideal_insurance")
          @rejected = group_key.include?("rejected")

          @all_check_groups = group_checks
          
          @all_check_groups.each_with_index do |checks, index|
            @sub_group_index = sub_grp_indx_ary[index]
            @checks = checks
            if @sub_group_index == 0
              @payer_name = get_payer_name_in_subtotal_header
            end
            yield
          end
        end
      else
        @checks = chk_grps[group_key]
        yield
      end
  
    else
      @batches.each do |btch|      
        @counter = 0
        @current_batch = btch
        if @config.primary_group == "payer"
          @all_checks = get_operation_log_checks(@config.job_status_grouping, btch.id)
          groups = @all_checks.group_by{|b| get_payer_criteria(b).to_s}
          if config.by_cpid || config.by_nextgen
            groups.keys.each do |k|
              groups[k]  = groups[k].sort{|a,b| payer_name_for_check(a) <=> payer_name_for_check(b)} 
            end
            group_keys = groups.keys.sort{|a,b| payer_name_for_check(groups[a].first) <=> payer_name_for_check(groups[b].first)}
          else
            group_keys = groups.keys.sort
          end          
          
          group_keys.each_with_index do |k,i|
            @checks = groups[k]    
            @generate_batch_summary = true if i == (group_keys.size - 1)
            yield
          end                
          
        else
          @checks = get_operation_log_checks(@config.job_status_grouping, btch.id)
          yield
        end
      end
    end
  end

  #this methods looks at the headers and for each headers invokes the method to get the data
  #does and eval after converting the headers to a string which represents the method
  def evaluate_row_from_headers(record_type)
    row_str = "\n"
    #row_str = config.header_fields.collect.map{|fld| eval("eval_" + fld.first.downcase.gsub(/(#|\(|\)| )/, "_") +  fld[2])}.join(@delimiter )
    if record_type == "plb"
      plb_field_list = ["Patient First Name", "Patient Last Name", 
        "Patient Account Number", "835 Amount", "Xpeditor Document Number",
        "Total Charge", "Date Of Service", "Reject Reason", "Statement #", 
        "Member Id", "Patient Date Of Birth", "Payer Name", "Reason Not Processed",
        "837 File Type", "PLB", "Unique Identifier", "Client Code", "Payer", 
        "MRN", "Service Provider ID", "Transaction Type"]
      row_str = row_str + config.header_fields.collect.map{|fld|
        if plb_field_list.include?(fld.first)
          eval("eval_plb_" + fld.first.downcase.gsub(/(#|\(|\)| |\/)/, "_"))  
        else 
          eval("eval_" + fld.first.downcase.gsub(/(#|\(|\)| |\/)/, "_"))
        end
      }.join(@delimiter)   
    elsif record_type == "extra plb"
      plb_field_list = ["Patient First Name", "Patient Last Name",
        "835 Amount", "Xpeditor Document Number",
        "Total Charge", "Date Of Service", "Reject Reason", "Statement #",
        "Member Id", "Patient Date Of Birth", "Reason Not Processed",
        "837 File Type", "PLB", "Unique Identifier", "Client Code"]
      row_str = row_str + config.header_fields.collect.map{|fld|
        if plb_field_list.include?(fld.first)
          eval("eval_extra_plb_" + fld.first.downcase.gsub(/(#|\(|\)| |\/)/, "_"))
        else
          eval("eval_" + fld.first.downcase.gsub(/(#|\(|\)| |\/)/, "_"))
        end
      }.join(@delimiter)
    else
      row_str = row_str + config.header_fields.collect.map{|fld| eval("eval_" + fld.first.downcase.gsub(/(#|\(|\)| |\/)/, "_"))}.join(@delimiter)
    end
    row_str = row_str + @delimiter +   Array.new(@config.custom_header_fields.size).join(@delimiter)  if @config.custom_header_fields.size > 0
    row_str 
  end  

  
  def summerize_groups
    total_columns = @headers.split(@delimiter).size
    batch_name_position = @config.header_fields.index{|x| x.first == "Batch Name"}
    check_position = @config.header_fields.index{|x| x.first == "Check"}
    check_position = 1 if !check_position
    check_amount_position = @config.header_fields.index{|x| x.first == "Check Amount"}
    amount_835_position = @config.header_fields.index{|x| x.first == "835 Amount"}
    eft_amount_position = @config.header_fields.index{|x| x.first == "Eft Amount"}
    sub_total_position = @config.header_fields.index{|x| x.first == "Sub Total"}

    _summary = "" # this is to hold  the first_summary if have to return two summaries
    summerize_columns = Array.new(total_columns)
    if @config.primary_group == "payer" || @config.by_nextgen
      if @config.payer_total
        if batch_name_position 
          _lbl = @config.get_label_for_total "Payer Total"
          if config.by_cpid || config.by_nextgen
            payer_group_total_header = (@sub_group_index > 0) ? "Total For  #{@payer_name}_#{@sub_group_index}" : "Total For  #{@payer_name}"
          else
            @payer_name = get_payer_name_in_subtotal_header
            payer_group_total_header = "Total For  #{@payer_name}"
          end
          summerize_columns[batch_name_position] = payer_group_total_header if _lbl != "NOLABEL"
        end
        _sum_check_amount = sum_check_amount(false)
        summerize_columns[sub_total_position] = ("%.2f" % _sum_check_amount) if sub_total_position
        summerize_columns[check_amount_position] = ("%.2f" % sum_check_amount) if check_amount_position && !sub_total_position
        summerize_columns[amount_835_position] = ("%.2f" % sum_835_amount(false)) if amount_835_position
        summerize_columns[eft_amount_position] = ("%.2f" % sum_eft_amount) if eft_amount_position
      end
      
      if @generate_batch_summary           
        _summary = summerize_columns.join(@delimiter)  if @config.payer_total
        summerize_columns = Array.new(total_columns)
        temp_checks = @checks
        @checks = @all_checks
        #if @config.batch_total && !@config.without_batch_grouping
        if check_position
          _lbl = @config.get_label_for_total "Batch Total"
          summerize_columns[check_position] = "GRAND TOTAL FOR BATCH - #{@current_batch.real_batch_id}"  if _lbl != "NOLABEL"
        end
        summerize_columns[sub_total_position] = ("%.2f" % sum_check_amount) if sub_total_position
        summerize_columns[check_amount_position] = ("%.2f" % sum_check_amount) if check_amount_position && !sub_total_position
        summerize_columns[amount_835_position] = ("%.2f" % sum_835_amount) if amount_835_position
        summerize_columns[eft_amount_position] = ("%.2f" % sum_eft_amount) if eft_amount_position
        #end
        summerize_columns = [] if !@config.batch_total 
        @checks = temp_checks
        @generate_batch_summary = false
      end      
      
    else
      #if @config.batch_total
      if check_position
        _lbl = @config.get_label_for_total "Batch Total"
        summerize_columns[check_position] = "GRAND TOTAL FOR BATCH -  #{@current_batch.real_batch_id}" if _lbl != "NOLABEL"
      end
      summerize_columns[sub_total_position] = ("%.2f" % sum_check_amount) if sub_total_position
      summerize_columns[check_amount_position] = ("%.2f" % sum_check_amount) if check_amount_position && !sub_total_position
      summerize_columns[amount_835_position] = ("%.2f" % sum_835_amount) if amount_835_position
      summerize_columns[eft_amount_position] = ("%.2f" % sum_eft_amount) if eft_amount_position
      #end
      summerize_columns = [] if !@config.batch_total 
    end
    _summ_siz = _summary.split(@delimiter).select{|j| j.present?}.size
    _summ_col_size = summerize_columns.select{|j| j.present?}.size
    _summary = "\n" + _summary if _summ_siz > 0
    return _summary + (_summ_col_size > 0 ? "\n" : "") + summerize_columns.join(@delimiter)
    
  end

  def get_gcbs_insurance_eobs check
    if @nextgen_insurance
      @eobs = check.nextgen_eobs_for_goodman
    elsif @ideal_insurance
      @eobs = check.old_eobs_for_goodman
    end
    @eobs
  end

  def complete_check_amount_condition
    (@nextgen_patpay || @ideal_patpay || @rejected)
  end

  def sum_check_amount (opt=true)
    @check_amount_total = 0
    eft_amount =  config.header_fields.index{|x| x.first == "Eft Amount"}
    if @client.name.upcase == "GOODMAN CAMPBELL"
      check_amount_total = 0
      @checks.each do |check|
        if eft_amount && check.payment_method == 'EFT'
          check_amount_total += 0.00
        else
          get_gcbs_insurance_eobs(check)
          check_amount = complete_check_amount_condition ? check.check_amount.to_f : check.eob_amount_calculated(@eobs, @nextgen_insurance)
          check_amount_total += check_amount.to_f
        end
      end
      @total_check_amount = @total_check_amount + check_amount_total if opt && check_amount_total
      @check_amount_total = check_amount_total
    else
      @checks.each do |check|
        if eft_amount && check.payment_method == 'EFT'
          @check_amount_total += 0.00
        else
          @check_amount_total += check.check_amount.to_f
        end
      end
      @total_check_amount = @total_check_amount + @check_amount_total if opt && @check_amount_total
    end
    @check_amount_total
  end


  #this mehtod should be moved to db,
  def sum_835_amount (opt=true)
    net_835_amt = 0
    if @client.name.upcase == "GOODMAN CAMPBELL"
      @checks.each do |check|
        total_835_amt = 0
        get_gcbs_insurance_eobs(check)
        total_835_amt = complete_check_amount_condition ? check.check_amount.to_f : check.eob_amount_calculated(@eobs, @nextgen_insurance)
        net_835_amt += total_835_amt.to_f
      end
    else
      @checks.each do |check|
        total_835_amt = 0
        insurance_payment_eobs = check.insurance_payment_eobs
        patient_pay_eobs = check.patient_pay_eobs
        unless insurance_payment_eobs.blank?
          insurance_payment_eobs.each do |ins_pay_eob|
            total_835_amt += ins_pay_eob.total_amount_paid_for_claim.to_f
            total_835_amt += ins_pay_eob.late_filing_charge.to_f
            if facility.details[:interest_in_service_line].blank?
              total_835_amt += ins_pay_eob.claim_interest.to_f
            end
          end
        end
        unless patient_pay_eobs.blank?
          patient_pay_eobs.each do |pat_pay_eob|
            total_835_amt += pat_pay_eob.stub_amount.to_f
          end
        end
        unless config.content_layout.downcase == "eob"
          total_835_amt += check.provider_adjustment_amount.to_f
        end
        if !check.job.provider_adjustments.blank? && config.content_layout.downcase == "eob" &&
            config.print_plb == "print plb"
          total_835_amt += check.job.provider_adjustments.sum('amount').to_f
        end
        net_835_amt += total_835_amt.to_f
      end
    end
    @total_835_amount = @total_835_amount + net_835_amt if opt
    sprintf("%.2f", net_835_amt)   
  end

  #this method is also inefficient
  def sum_eft_amount (opt=true)
    total_eft_amt = 0
    if @client.name.upcase == "GOODMAN CAMPBELL"
      @checks.each do |check|
        if check.payment_method == 'EFT'
          get_gcbs_insurance_eobs(check)
          check_amount = complete_check_amount_condition ? check.check_amount.to_f : check.eob_amount_calculated(@eobs, @nextgen_insurance)
          total_eft_amt += check_amount.to_f
        else
          total_eft_amt += 0.00
        end
      end
      @total_eft_amount = @total_eft_amount + total_eft_amt if opt
    else
      @checks.each do |check|
        if check.payment_method == 'EFT'
          total_eft_amt += check.check_amount.to_f
        else
          total_eft_amt += 0.00
        end
      end
      @total_eft_amount = @total_eft_amount + total_eft_amt if opt
    end
    total_eft_amt
  end

  def summary_check_amount(job_status)
    Batch.sum_check_amount(@batches.collect(&:id), job_status)
  end

  def summary_hospital_check_amount(job_status)
    Batch.sum_hospital_check_amount(@batches.collect(&:id), job_status)
  end

  def summary_physician_check_amount(job_status)
    Batch.sum_check_amount(@batches.collect(&:id), job_status)
  end

  def summerize_total
    @total_accepted_amount = summary_check_amount(JobStatus::COMPLETED)
    @total_rejected_amount = summary_check_amount(JobStatus::INCOMPLETED)
    @total_deposit_amount = @total_rejected_amount + @total_accepted_amount
    @total_unidentified_amount = @total_deposit_amount - (@total_hospital_amount + @total_physician_amount)
  end

  
  def total_summary
    summerize_total
    header_row if @headers.blank?
    total_columns = @headers.split(@delimiter).size
    summary = Array.new(total_columns)
    str = ""
    if @config.summary_fields.first.present?
      if @config.show_summary_header
        if  @config.summary_position.ends_with?("right")
          str <<  "\n" + @delimiter*(total_columns -1) + @config.summary_header 
        else
          str << "\n" + @config.summary_header +  @delimiter*(total_columns -1) + "\n"         
        end
      end
      
      @config.summary_fields.each do |fields|
        if @config.summary_position.ends_with?("right")
          summary[total_columns-1] =  (fields[1].present? ? fields[1] : fields[0] ) + ": " +  eval("\"%.2f\" % @"+fields[0].downcase.gsub(" ","_") ) 
        else
          summary[0] =  (fields[1].present? ? fields[1] : fields[0] ) + ": " +  eval("\"%.2f\" % @"+fields[0].downcase.gsub(" ","_")) 
        end
        str <<  "\n" +  summary.join(@delimiter) 
      end
      str << "\n"
    end
    str
  end



  def grand_and_deposit_summary
    grand_and_deposit = ""
    total_columns = @headers.split(@delimiter).size
    summerize_columns = Array.new(total_columns)
    check_number_position = @config.header_fields.index{|x| x.first == "Check Number"} || 2
    check_amount_position = @config.header_fields.index{|x| x.first == "Check Amount"}
    if check_number_position > check_amount_position
      check_number_position = check_amount_position - 1
    end
    amount_835_position = @config.header_fields.index{|x| x.first == "835 Amount"}
    eft_amount_position = @config.header_fields.index{|x| x.first == "Eft Amount"}
    sub_total_position = @config.header_fields.index{|x| x.first == "Sub Total"}
    _gtlbl = @config.get_label_for_total "Grand Total"
    _gtlbl = "Grand Total" if _gtlbl.blank?
    if @config.grand_total && @config.by_nextgen
      summerize_columns = Array.new(total_columns)
      summerize_columns[check_number_position] = _gtlbl
      summerize_columns[check_amount_position] = ("%.2f" % @total_check_amount) if check_amount_position && ! sub_total_position
      summerize_columns[sub_total_position] = ("%.2f" % @total_check_amount) if sub_total_position
      summerize_columns[eft_amount_position] = ("%.2f" % @total_eft_amount) if eft_amount_position
      grand_and_deposit = grand_and_deposit + "\n" + summerize_columns.join(@delimiter)
    elsif @config.grand_total && @config.without_batch_grouping && !@config.for_facility
      summerize_columns = Array.new(total_columns)
      summerize_columns[check_number_position] = _gtlbl
      _accpt_amt = summary_check_amount(JobStatus::COMPLETED)
      _rej_amt = summary_check_amount(JobStatus::INCOMPLETED)
      _dep_amt = _accpt_amt + _rej_amt
      summerize_columns[check_amount_position] = ("%.2f" % _dep_amt) if check_amount_position && ! sub_total_position
      summerize_columns[sub_total_position] = ("%.2f" % _dep_amt) if sub_total_position
      grand_and_deposit = grand_and_deposit + "\n" + summerize_columns.join(@delimiter)
    elsif @config.grand_total && !@config.for_facility
      summerize_columns = Array.new(total_columns)
      summerize_columns[check_number_position] = _gtlbl
      summerize_columns[check_amount_position] = ("%.2f" % @total_check_amount) if check_amount_position && ! sub_total_position
      summerize_columns[sub_total_position] = ("%.2f" % @total_check_amount) if sub_total_position
      summerize_columns[amount_835_position] = ("%.2f" % @total_835_amount) if amount_835_position
      summerize_columns[eft_amount_position] = ("%.2f" % @total_eft_amount) if eft_amount_position
      grand_and_deposit = grand_and_deposit + "\n" + summerize_columns.join(@delimiter)
    elsif @config.grand_total && @config.for_facility
      summerize_columns[check_number_position] = _gtlbl
      summerize_columns[check_amount_position] =  ("%.2f" % @total_client_check_amount) if check_amount_position && ! sub_total_position
      summerize_columns[sub_total_position] = ("%.2f" % @total_client_check_amount) if sub_total_position
      summerize_columns[amount_835_position] = ("%.2f" % @total_client_835_amount) if amount_835_position
      summerize_columns[eft_amount_position] = ("%.2f" % @total_client_eft_amount) if eft_amount_position
      grand_and_deposit = grand_and_deposit + "\n" + summerize_columns.join(@delimiter)
    end
    
    if @config.deposit_total
      summerize_columns = Array.new(total_columns)
      summerize_columns[check_number_position] = "Deposit Total"
      if check_amount_position
        if @config.for_facility
          summerize_columns[check_amount_position] = ("%.2f" % @total_client_check_amount)
        else
          summerize_columns[check_amount_position] = ("%.2f" %  @total_check_amount)
        end
      end
      grand_and_deposit = grand_and_deposit + "\n" + summerize_columns.join(@delimiter)
    end
    grand_and_deposit
  end

  def get_payer_name_in_subtotal_header
    payer_name =  eval_first_payer_name
    payer_criteria = get_payer_criteria(@checks.first,false)
    if payer_criteria  == "patpay"
      payer_name = "self pay 835 format"
    elsif payer_criteria == "queue_nextgen"
      payer_name = "NextGen format"
    elsif payer_criteria == "rejected"
      payer_name = "Rejected checks"
    end
    payer_name
  end


  def get_payer_criteria check, opt=true
    if config.by_cpid && opt && !rejected_check?(check)
      return  get_payer_cpid_criteria(check)
    end
    check_payer = check.payer
    job = check.job
    if check_payer
      job_payer_group = job.payer_group
      payer_type = job_payer_group ? job_payer_group.downcase : ""
    end
    if nextgen_check?(check)
      "queue_nextgen"
    elsif payer_type == "patpay"
      "patpay"
    elsif rejected_check?(check) && (config.by_cpid || config.by_nextgen)
      "rejected"
    else
      if check.micr_line_information
        check.micr_line_information.payer
      else
        if check_payer
          return check_payer.payer
        else
          ""
        end
      end
    end    
  end
  

  def get_payer_cpid_criteria check
    check_payer = check.payer
    Output835.oplog_log.info "Check Payer: #{check_payer.payer}"
    if check.micr_line_information
      payer = check.micr_line_information.payer
      Output835.oplog_log.info "Check's MICR associated Payer: #{payer.payer}"
      payer ? payer.output_payid(facility) : nil
    elsif check_payer
      check_payer.output_payid(facility)
    else
      nil
    end
  end

  def nextgen_check?(check)
    # EOBs processed in nextgen grid will have no payer
    # they will be stored in patient_pay_eobs table
    # nextgen grid is rendered only when specified so, thru FC UI
    (!check.patient_pay_eobs.blank? &&
        check.batch.facility.patient_pay_format == 'Nextgen Format')
  end
  
  def rejected_check?(check)
    check.job.job_status == JobStatus::INCOMPLETED && !check.correspondence?
  end
  
end
