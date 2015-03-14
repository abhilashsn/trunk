# To change this template, choose Tools | Templates
# and open the template in the editor.

class EobSegregator
  def initialize(ins_grouping = 'by_batch', pat_grouping = 'by_batch')
    @ins_grouping = ins_grouping
    @pat_grouping = pat_grouping
    @zip_type = []
  end

  #This method takes in an array of batchids and return a two dimentional array of eobs
  #first dimension represents the object used for grouping, resulting in one output file per element
  #second dimension represents the checks and eobs in each output file
  def segregate(batch_id,eob_groups)
    eobs = eob_groups
    @batch = Batch.find(:first,:conditions=>"id in (#{batch_id})")
    @zip_type = eobs.collect(&:check_information).collect(&:batch).collect(&:correspondence).uniq
    eobs = eobs.delete_if {|c| c.check_information.job.incomplete? && c.check_information.job.is_excluded == true}
    check_eob = {}
    eobs.each do |eob|
      check_id = eob.check_information_id
      file_name = group_name(eob,@batch)
      unless file_name.blank?
        check_eob[file_name] = {} unless check_eob.key?file_name
        check_eob[file_name].merge!({check_id => []}) unless check_eob[file_name].key?check_id
        check_eob[file_name][check_id] << eob
      end
    end
    return check_eob
  end

  # Returns the computed group name for a eob
  # by applying the grouping passed to it
  # group name also depends on certain other parameters
  # configured for a facility
  def group_name(eob,batch)
    site_code = batch.facility.sitecode.downcase
    site_code.gsub!(/^0*/,'')
    method = "group_name"
    if self.methods.include?("#{method}_#{site_code}".to_sym)
      method << "_#{site_code}"
    else
      Output835.log.info "Please check the site_code. (Method #{method}_#{site_code} is missing...)"
      raise ArgumentError, "Please check the site_code. (Method #{method}_#{site_code} is missing...)"
    end
    eob_groups = send(method,eob,batch)
    return eob_groups
  end
    
  def group_name_549 (eob,batch)
    account_number = eob.patient_account_number
    financial_class_value = ""
    if (account_number[0,3].upcase == "SAL")
      financial_class_value = "SAL"
    else
      unless eob.claim_information_id.blank?
        business_indicator = BusinessUnitIndicatorLookupField.business_indicator(eob.claim_information_id)
        financial_class_value = financial_class(business_indicator)
      end
      financial_class_value = "TROTH"  if (financial_class_value.empty?)
    end
    batch_type = (batch.correspondence == true) ? "COR" : "PAY"
    if !batch.index_batch_number.blank? and !eob.payer_indicator.blank?
      batch_date = batch.date.strftime("%y%m%d")[1..-1]
      "#{financial_class_value}#{batch_date}#{batch.cut}_#{batch.index_batch_number.slice(0,3)}_#{batch_type}_#{eob.payer_indicator}.835"
    else
      Output835.log.info "Unable to generate file. Value(s) of Index_batch_number / Payer_indicator missing."
      raise ArgumentError, "Unable to generate file. Value(s) of Index_batch_number / Payer_indicator missing."
    end
  end

   
  def financial_class(business_indicator_code)
    financial_code = ""
    case business_indicator_code
    when 'HJD'
      financial_code = business_indicator_code
    when 'TSH'
      financial_code = 'TIS'
    when 'RSK'
      financial_code = 'RUS'
    end
    return financial_code
  end

  def group_name_834(eob,batch)
    @eob_group_name = nil
    service_codes = ['94060','90821','90826','93010','96116','90818','96118','90806','94620','94010','94240','94720','99215','99212','15340','15341','11042','99243','99242','10160','99211','99213','99203','93922','11041','99244','17250']
    service_procedure_amount = [45.00,90.00,135.00,225.00]
    service_eobs = eob.service_payment_eobs
    payer = eob.check_information.payer.payer.upcase
    account_number = eob.patient_account_number
    account_digits = Array(0..9).to_s
    batch_date = batch.date
    batch_index_number = batch.index_batch_number
    facility_sitecode = batch.facility.sitecode
    service_eobs.each do |service_eob|
      eob_group_b_condition = (service_codes.include?(service_eob.service_procedure_code)) or (payer == "GEORGIA BLUE CROSS" and service_procedure_amount.include?(service_eob.service_procedure_charge_amount))
      if (eob_group_b_condition)
        @eob_group_name = "B"
      end
    end
    if (@eob_group_name.nil?)
      if (account_number[0,2].upcase == "WR")
        @eob_group_name = "C"
      elsif (account_number[0,1].upcase == "W" and (account_digits.include?account_number[1,1]))
        @eob_group_name = "D"
      elsif (account_number[0,3].upcase == "WLB")
        @eob_group_name = "G"
      elsif (account_number[0,3].upcase == "WHS")
        @eob_group_name = "F"
      else
        @eob_group_name = "A" 
      end
    end
    if !@eob_group_name.blank? and !batch_date.blank? and !batch_index_number.blank? and !facility_sitecode.blank?
      "#{batch_date.strftime("%m%d")}#{batch_index_number}#{facility_sitecode.slice(2,3)}#{@eob_group_name}"+".835"
    else
      Output835.log.info "Unable to generate file. Value of Index_batch_number is missing."
      raise ArgumentError, "Unable to generate file. Value of Index_batch_number is missing."
    end
  end

  def group_name_c2q(eob,batch)
    lockbox = batch.lockbox
    check_information = eob.check_information
    check_amount = check_information.check_amount
    payid = check_information.payer.payer_identifier(check_information.micr_line_information)
    if lockbox == "134028"
      eob_group = group_name_chmp_lockbox_134028(check_amount,payid)
    else
      eob_group = group_name_chmp_lockbox(check_amount,payid)
    end
    if !eob_group.blank?
      "HLSCBATCH#{eob_group.slice(1,1)}#{batch.date.strftime("%y%m%d")[1..-1]}#{batch.cut}.DAT"
    else
      Output835.log.info "Unable to generate file. Value(s) of Lockbox / Payid missing."
      raise ArgumentError, "Unable to generate file. Value(s) of Lockbox / Payid missing."
    end
  end
   
  def group_name_chmp_lockbox_134028(check_amount,payid)
    if check_amount == 0.01
      eob_group = "B7"
    elsif  payid == "0SELF"
      eob_group = "B6"
    else
      eob_group = "B8"
    end
    return eob_group
  end

  def group_name_chmp_lockbox(check_amount,payid)
    if check_amount == 0.01
      eob_group = "B4"
    elsif  payid == "0SELF"
      eob_group = "B3"
    elsif  payid == "P2109"
      eob_group = "B9"
    else
      eob_group = "B1"
    end
    return eob_group
  end

  def group_name_k38(eob,batch)
    account_number = eob.patient_account_number
    batch_date = batch.date.strftime("%y%m%d")
    batch_cut = batch.cut
    batch_type = (batch.correspondence == true) ? "COR" : "PAY"
    unless  account_number == "999999999"
      if (account_number[0,1].upcase == "I")
        eob_group = "AMCH"
      elsif (account_number[0,3].upcase == "03M")
        eob_group = "BMCP"
      else
        eob_group = "ZMCP"
      end
      if !eob_group.blank? and !batch_date.blank? and !batch_cut.blank?
        "UB#{batch_date[1..-1]}#{batch_cut}#{eob_group}#{batch_type}.835"
      else
        Output835.log.info "Unable to generate file. Value(s) of eob_group/batch_date/cut is(are) missing."
        raise ArgumentError, "Unable to generate file. Value(s) of eob_group/batch_date/cut is(are) missing."
      end
    end
  end

  def group_name_mo(eob,batch)
    batch_date = batch.date.strftime("%m%d%y")
    batch_id = batch.batchid
    account_number = eob.patient_account_number
    if (account_number[0,2].upcase == "MO")
      account_type = "MO"
    else
      account_type = "OTHERS"
    end
    if eob.check_information.check_number.blank?
      file_type = "COR"
    else
      file_type = payer_type(eob.check_information)
    end
    "#{batch_date}_#{account_type}_#{batch_id}_#{file_type}.835"
  end

  def payer_type(check)
    if check.micr_line_information && check.micr_line_information.payer
      payer_type = check.micr_line_information.payer.payer_type
    else
      payer_type = check.payer.payer_type
    end
    if payer_type.upcase == 'PATPAY'
      return payer_type.upcase
    else
      return "INS"
    end
  end

  def group_name_k29(eob,batch)
    batch_date = batch.date.strftime("%y%m%d")
    payid = eob.check_information.payer.payer_identifier(eob.check_information.micr_line_information)
   
    payid_array = ["MABX1", "P0730","96911","11109","P0610","95541","80314","P0772","66828"]
    if payid_array.include?(payid)
      eob_group = "US"
    else
      eob_group = "UB"
    end
    if !eob_group.blank? and !payid.blank? and !batch_date.blank?
      "#{eob_group}_201#{batch_date[1..-1]}_835.TXT"
    else
      Output835.log.info "Unable to generate file. Value(s) of eob_group/payid/batch_date is(are) missing."
      raise ArgumentError, "Unable to generate file. Value(s) of eob_group/payid/batch_date is(are) missing."
    end
  end
  
  def group_name_501(eob,batch)
    check_information = eob.check_information
    batch = check_information.job.batch
    payid = check_information.payer.payer_identifier(check_information.micr_line_information)
    #The following payids should go to D.835
    file_d_payid_array = ["NADX1","P0425","90859","64548","93629","P0323","63405","87980",
      "95520","95708","96563","95518","95383","95606","95635","P2561","95121","95209","95488",
      "95500","95132","95447","95600","95602","96229","95136","95544","95660","95604","95125",
      "95493","95599","95525","11167","47013","52617","95037","47041","47805","47001","95179",
      "11160","48119","52108"]
    #The following payids should go to E.835
    file_e_payid_array = ["CMUN1","87726","P1108","P5885","95755","47095","95501","95765",
      "11147","47083","95186","95085","95080","95149","95103","96385","95591","95833","96644",
      "95776","95850","59129","95264","95090","96016","95446","95784","95025","11596","73518",
      "60093","60318","79413","95703","95716"]
    #The following payids should go to F.835
    file_f_payid_array = ["23222","60054","PG630","PH052","P0498","36153","95023","47060",
      "95343","95397","84450","65200","95484","95490","95006","95109","95757","96518","95234",
      "95287","95237","95810","95756","95517","95590","95236","95002","95094",
      "95088","95245","95935","95256","95003","78700","47039","11183","47077","95910",
      "52026","NAAD2"]

    if batch.correspondence == true || payid == "0SELF"
      file_prefix = "C"
    elsif payid == "P7736"
      file_prefix = "G"
    elsif file_d_payid_array.include?(payid)
      file_prefix = "D"
    elsif file_e_payid_array.include?(payid)
      file_prefix = "E"
    elsif file_f_payid_array.include?(payid)
      file_prefix = "F"
    else
      file_prefix = "B"
    end
    batch_date = batch.date.strftime("%y%m%d")[1..-1]
    batch_cut = batch.cut
    batch_index_number = batch.index_batch_number
    if ["A","B","C"].include?(file_prefix)
      file_name = "#{file_prefix}#{batch_date}#{batch_cut}.835"
    else
      file_name = "#{file_prefix}#{batch_date}#{batch_cut}_#{batch_index_number}.835"
    end
    return file_name
  end

   def zip_type
    if @zip_type.count == 2
      @zip_ext_type = "ZIP"
    elsif @zip_type.count == 1 and @zip_type.include?(true)
      @zip_ext_type = "COR"
    else
      if @zip_type.count == 1 and @zip_type.include?(false)
        @zip_ext_type = "PAY"
      end
    end
  end
end
