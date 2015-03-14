#===============================================================================
# A library class generating EDC Human Readable EOB by taking EOB id and output
# file name and location as input parameter.
# 
# The class depends on a configuration file edc_hr_eob_conf.yml for output
# formating and styling.
#===============================================================================

module HrEobHelper

  def repeat(char, cnt = 1)
    return char * cnt
  end
  
  def carg_return(cnt = 1)
    return repeat("\r\n", cnt)
  end
  
  def ralign(str, len = str.length)
    ((str.nil? or str.blank?) ? '' : str.rjust(len))
  end

  def lalign(str, len = str.length)
    str.ljust(len)
  end

  def format_date(dt, frmt = "%m/%d/%Y")
    ((dt.nil? or dt.blank?) ? '' : dt.strftime(frmt))
  end
  
  def process(ar, j = '')
    est = ''
    begin
      ar.collect { |i| est = i; eval(i) }.join(j)
    rescue Exception => e
      Rails.logger.error "HREOB Error: " << e.to_s
      Rails.logger.error "Error in statement - " << est
      ''
    end
  end
  
end

class EDCHrEob
  include HrEobHelper

  attr_reader :btch, :chk, :eob, :cnf, :srv_itm, :op_file, :loc, :adjr, :l_c_d, :rcc
  
  def initialize(dir_loc)
    if File.directory?(dir_loc) 
      @loc = dir_loc
    else
      raise "Expecting a directory!"
    end
    @cnf = YAML::load(File.open("#{Rails.root}/lib/HREOB/edc_hr_eob_conf.yml"))
  end

  def generate_edc_hr_eob(b_id)
    # Payer exclusion
    @btch = Batch.where("jobs.job_status != '#{JobStatus::EXCLUDED}'").includes([{:facility => [:client]},{:check_informations => [:payer,{:insurance_payment_eobs => :service_payment_eobs}]}]).find(b_id)
    
    # Purge previous log records for the batch. Only lastest output information will be logged.
    OutputActivityLog.purge_last_log(b_id)

    gc = 0
    if btch.present?
      
      Rails.logger.error "No check information for Batch id #{b_id}" if btch.check_informations.blank?
      
      btch.check_informations.each do |_chk|
        @chk = _chk
        Rails.logger.debug "HREob generating for check id #{@chk.id} & Batch #{btch.id}"

        # This is stand-by to over come the following error.
        # lib\HREOB\EDCHrEob.rb:35:in `process': lib\HREOB\EDCHrEob.rb:35:in `process': (eval):1:in `check_date': wrong number of arguments (0 for 2) (ArgumentError)
        @l_c_d = @chk.check_date

        @rcc = ReasonCodeCrosswalk.new(chk.payer, nil, @btch.facility.client, @btch.facility) # if ! chk.payer.blank?
        c = 0
        chk.insurance_payment_eobs.each do |_eob| 
          @eob = _eob
          
          begin
            prepare_edc_hr_eob
          rescue Exception => e
            Rails.logger.error "Unable to generate HREOB for EOB #{@eob.id} of Check #{@chk.id} & Batch #{btch.id}. Due to - " << e.to_s
          end
          
          c = c + 1 
        end
          
        
        Rails.logger.debug "For the Check #{@chk.id} & Batch #{btch.id} HREobs generated are #{c}"

        gc = gc + c
      end
    else
      Rails.logger.error "Unable to locate Batch id #{b_id}"
    end

    Rails.logger.debug "For the Batch #{btch.id} HREobs generated are #{gc}"
  end
  
  private
  
  def prepare_edc_hr_eob

    # File naming pattern ?ImageFilename?_?ClaimGUID?.?eob?
    fname = "#{loc}/#{eob_file_name}_#{eob.guid}.eob"
    @op_file = File.new(fname, "w")

    op_file.write process(cnf['makeup_eob'])
    prepare_adj_reasons
    makeup_eob_items
    
    op_file.close
                                          
    # Post output file details to output_activity_logs & eobs_output_activity_logs
    OutputActivityLog.post_file_info(fname, @eob, @btch)

    Rails.logger.debug "HREob generated for EoB #{@eob.id} & Check #{@chk.id} in #{fname}"

  end
  
  def makeup_eob_items
    op_file.write process(cnf['makeup_eob_service_item_header'])
    #@eob.service_payment_eobs.each { |@srv_itm| op_file.write process(cnf['makeup_eob_service_items']) }
    @eob.service_payment_eobs.each do |_srv_itm|
      @srv_itm = _srv_itm
      op_file.write process(cnf['makeup_eob_service_items'])
    end
    op_file.write process(cnf['makeup_eob_service_items_total'])
  end


  def prepare_adj_reasons
    
    # Adj Reason Code indentation flag
    indent = false
    
    @rcc.instance_variable_set("@entity", eob)
    
    if ! eob.total_co_insurance.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('coinsurance')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_co_insurance.to_f) << carg_return
    end
    
    if ! eob.total_contractual_amount.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('contractual')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_contractual_amount.to_f) << carg_return
    end

    if ! eob.total_co_pay.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('copay')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_co_pay.to_f) << carg_return
    end

    if ! eob.total_deductible.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('deductible')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_deductible.to_f) << carg_return
    end

    if ! eob.total_denied.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('denied')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_denied.to_f) << carg_return
    end

    if ! eob.total_discount.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('discount')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_discount.to_f) << carg_return
    end

    if ! eob.total_non_covered.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('noncovered')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_non_covered.to_f) << carg_return
    end

    if ! eob.total_primary_payer_amount.to_f.zero?
      rslt = rcc.get_crosswalked_codes_for_adjustment_reason('primary_payment')
      indent = add_space(indent)
      op_file.write sprintf('%-3s %-15s %6.02f', rslt[:cas_01], rslt[:cas_02], eob.total_primary_payer_amount.to_f) << carg_return
    end
    
    op_file.write carg_return if ! indent

  end
  
  def collect_srv_line_reason(srvln)
    rslt = @rcc.get_all_codes_for_entity(srvln, true)
    rslt[:all_reason_codes].join(';')
  end
  
  def add_space(ind)
    result = ind
    if ind
      op_file.write repeat(' ', 18) 
    else
      result = true
    end
    result
  end
  
  def eob_file_name
    img_fl_name = eob.image_file_name
    File.basename(img_fl_name, File.extname(img_fl_name))
  end
  
end # class EDCHrEob

#hreob = EDCHrEob.new("#{Rails.root}/EDCHREOB_OP/")
#hreob.generate_edc_hr_eob(217)
