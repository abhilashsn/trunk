module OtherOutput
  module DataFetcherA36
    def load_objects image_type
      clean_slate
      @image_type  = image_type
      @insurance_payment_eob = @image_type.insurance_payment_eob 
      @images_for_job = @image_type.images_for_job 
      @service_payment_eobs = @insurance_payment_eob.service_payment_eobs  if @insurance_payment_eob
      @check_information = @insurance_payment_eob.check_information  if @insurance_payment_eob
      @check_information = @image_type.images_for_job.jobs.first.check_information if !@check_information rescue nil
      @job  = @check_information.job if @check_information
      @batch = @images_for_job.batch
      @micr = @check_information.micr_line_information if @check_information
      @payer = @micr.payer if @micr_line_information
      @payer = @check_information.payer if ! @payer && @check_information
      @facility = @batch.facility if @batch
      @batch_calculation_hash = {}
      @rcc = ReasonCodeCrosswalk.new(@payer, nil, @facility.client, @facility) # if ! chk.payer.blank?
    end

    
    
    def method_missing(sym, *args, &block)
      return "#{sym.to_s} method missing .."
    end

    def eval_aba_routing_number 
      @micr ? @micr.aba_routing_number : ""
    end

    def eval_batch_id
      @batch ? @batch.index_batch_number : ""
    end
    
    def eval_hcpcs_code
      @service_payment_eob.present? ? @service_payment_eob.service_procedure_code : ""
    end

    def eval_image_type
      @image_type.send("image_type")
    end
    

    def eval_line_allowed_amount
      @service_payment_eob ? @service_payment_eob.service_allowable : "0.0"      
    end
    
    def eval_line_coinsurance_amount
      @service_payment_eob ? @service_payment_eob.service_co_insurance : "0.0"
    end

    def eval_line_contractual_amount 
      @service_payment_eob ?  @service_payment_eob.contractual_amount : "0.0"
    end

    def eval_line_deductible_amount
      @service_payment_eob ?  @service_payment_eob.service_deductible  : "0.0"
    end
    
    def eval_line_denied_amount
      @service_payment_eob ? @service_payment_eob.denied : "0.0"
    end
    
    def eval_line_noncovered_charge
      @service_payment_eob ? @service_payment_eob.service_no_covered : "0.0"
    end

    def eval_line_service_date
      if @service_payment_eob && @service_payment_eob.date_of_service_from
        @service_payment_eob.date_of_service_from.strftime("%m%d%Y") 
      else
        ""
      end
    end

    def eval_line_primary_payor_payment_amount
      @service_payment_eob ?  @service_payment_eob.primary_payment  : "0.0"
    end

    def eval_line_payment_amount
      @service_payment_eob ?  @service_payment_eob.service_paid_amount  : "0.0"
    end

    def eval_line_total_charge
      @service_payment_eob ?  @service_payment_eob.service_procedure_charge_amount  : "0.0"
    end

    
    def eval_line_denied_amount
      @service_payment_eob ? @service_payment_eob.denied_amount  : ""
    end
    
    def eval_batch_date
      @batch ?  @batch.date : ""      
    end
    
    def eval_batch_type
      @batch ?  (@batch.correspondence == true ? "Correspondence" : "Payment" ) : ""
    end

    def eval_lockbox
      @batch ? @batch.lockbox : ""
    end
    
    def eval_patient_control_number
      return "0" if @image_type.send("image_type") != "EOB" 
      @insurance_payment_eob ?   @insurance_payment_eob.patient_account_number : ""
    end
    
    def eval_patient_name
      @insurance_payment_eob ?   @insurance_payment_eob.patient_name(true) : ""
    end

    def eval_payer_name
      client_name =  @facility ? @facility.client.name  : ""
      check_payer = @check_information.payer if @check_information
      payer_name = ""
      unless check_payer.nil?
        if check_payer.payer_type && check_payer.payer_type.downcase == "patpay" && client_name && client_name.downcase != "quadax"
          payer_name = "PATPAY"
        else
          is_micr_payer_present = @micr && @micr.payer && @facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? @micr.payer.payer : check_payer.payer
        end
      end
      payer_name.blank? ? '-' : payer_name          
    end

    
    def eval_payer_proprietary_adjustment_reason_code      
      if @facility && @facility.details["claim_level_eob"] == true
        rslt = @rcc.get_all_codes_for_entity(@insurance_payment_eob, true) if @insurance_payment_eob.present?
        reason_codes = @insurance_payment_eob.present?   ?  rslt[:primary_reason_codes].join(';') : ""
      else
        rslt = @rcc.get_all_codes_for_entity(@service_payment_eob, true) if @service_payment_eob.present?
        reason_codes = @service_payment_eob.present?   ?  rslt[:primary_reason_codes].join(';') : ""
      end
      return reason_codes
    end

    def eval_reason_code
      secondary_codes = ""
      if @facility && @facility.details["claim_level_eob"] == true
        rslt = @rcc.get_all_codes_for_entity(@insurance_payment_eob, true) if @insurance_payment_eob.present?
        secondary_codes = @insurance_payment_eob.present?   ?  rslt[:all_reason_codes].join(';') : ""
      else
        rslt = @rcc.get_all_codes_for_entity(@service_payment_eob, true) if @service_payment_eob.present?
        secondary_codes = @service_payment_eob.present?   ?  rslt[:all_reason_codes].join(';') : ""
      end
      secondary_codes
    end

    def eval_source_batch_file_name
      @batch ?  @batch.src_file_name : ""
    end

    def eval_trace_number
      begin
        (@insurance_payment_eob && @facility && @batch) ?  @insurance_payment_eob.trace_number(@facility, @batch) : ""
      rescue Exception => e
        ""
        #e.to_s  I should write a error logger for the ouput generation
      end
    end


    def eval_batch_time
      @batch && @batch.batch_time ? @batch.batch_time.to_s(:db).split(" ").last : ""
    end

    def eval_batch_total_payment_amount
      begin
        if !@batch_calculation_hash["batch_total_payment_amount:" + @batch.id.to_s]
          @batch_calculation_hash["batch_total_payment_amount:" + @batch.id.to_s]  = summary_check_amount(JobStatus::COMPLETED)
        end
          @batch_calculation_hash["batch_total_payment_amount:" + @batch.id.to_s]
      rescue Exception => e
        "Exception encountered!" + e.to_s
      end
    end
        
    def eval_check_account_number
      @micr ?  @micr.payer_account_number : ""
    end
    
    def eval_check_number
      @check_information ? @check_information.check_number : ""
    end

    def eval_raw_tif_image_file_name
      @images_for_job ? @images_for_job.filename : ""
    end
    
    def eval_hic
      if @insurance_payment_eob && @insurance_payment_eob.patient_identification_code_qualifier == "HIC"
        @insurance_payment_eob.patient_identification_code
      else
        ""
      end
    end

    def eval_dummy
      ""
    end



    def insert_service_line_headers fields
      header_fields = fields.clone
      line_items = ["HCPCS Code", "Line Allowed Amount","Line Contractual Amount", "Line Deductible Amount", "Line Non-Covered Charge","Line Payment Amount",
                    "Line Primary Payor Payment Amount", "Line Service Date", "Line Total Charge", "Line Denied Amount", "Line Coinsurance Amount", 
                    "Payer Proprietary Adjustment Reason Code","Reason Code"]
      line_items.each do |line_item|
        index = header_fields.index(header_fields.select{|j| j.first == line_item}.first)
        if index
          label = header_fields[index].last
          label = line_item if label.blank?
          header_fields[index] = [ line_item + " 1", transform_label(label, 1)]
          labels = Array.new()
          (2..6).each{|j| labels <<  [line_item + " #{j}", transform_label(label, j)]}
          header_fields.insert(index+1, *labels)
        end
      end      
      header_fields
    end


    def insert_service_line_values hsh,fields
      #if @service_payment_eobs.present?
        header_fields = fields.clone
        merge_hash = Hash.new()
        line_items = ["HCPCS Code", "Line Allowed Amount","Line Contractual Amount", "Line Deductible Amount", "Line Non-Covered Charge","Line Payment Amount",
                      "Line Primary Payor Payment Amount", "Line Service Date", "Line Total Charge", "Line Denied Amount", "Line Coinsurance Amount", 
                      "Payer Proprietary Adjustment Reason Code", "Reason Code"]
        line_items.each do |line_item|
          index = header_fields.index(header_fields.select{|j| j.first == line_item}.first)
          if index
            merge_hash.merge!(get_service_line_values(line_item))
          end
        end      
        hsh.merge(merge_hash)      
      #else
      #  return hsh
      #end
    end

    
    def get_service_line_values line_item
      keys = Array.new()
      (1..6).each{|j| keys << line_item + " #{j}"  }
      values = Array.new
      @service_payment_eobs.each do |service_payment_eob|        
        @service_payment_eob = service_payment_eob
        values << self.send("eval_#{line_item.downcase.gsub(/[^a-zA-Z ]/, "").strip.gsub(" ", "_")}")
      end
      line_items = ["Line Allowed Amount","Line Contractual Amount", "Line Deductible Amount", "Line Non-Covered Charge","Line Payment Amount",
                      "Line Primary Payor Payment Amount",  "Line Total Charge", "Line Denied Amount", "Line Coinsurance Amount"]                      
        
      if line_items.include?(line_item)
        (6-values.size).times do 
          values << "0.0"
        end
      end
      Hash[*(keys.zip(values).flatten)]      
    end    


    def summary_check_amount(job_status)
      Batch.sum_check_amount([@batch].collect(&:id), job_status)
    end


    def clean_slate
      @service_payment_eobs = []
      @check_information = nil
      @job = nil
      @batch = nil
      @micr = nil
      @payer = nil
      @facility = nil
    end

    
    def transform_label label, index
      repl = ["","A","B","C","D","E","F"]
      numeral = ["","1","2","3","4","5","6"]      
      if label =~ /::::/
        labels = label.split("::::")
        repl = labels.last.split(",")
        label = labels.first
      end
      if label =~ /\[ALPHA\]/
        label = label.gsub("[ALPHA]","[replace-me]")
      elsif label =~ /\[NUM\]/
        label = label.gsub("[NUM]","[replace-me]")
        repl = numeral
      elsif label =~ /\[CUSTOM\]/
        label = label.gsub("[CUSTOM]","[replace-me]")
      else
        label = label + "[replace-me]"
      end
      label = label.gsub("[replace-me]",repl[index])
      return label
    end    
    
  end
end
