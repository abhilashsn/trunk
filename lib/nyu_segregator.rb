# To change this template, choose Tools | Templates
# and open the template in the editor.

class NyuSegregator
  def initialize(ins_grouping = 'by_batch', pat_grouping = 'by_batch')
    @ins_grouping = ins_grouping
    @pat_grouping = pat_grouping
  end

  #This method takes in an array of batchids and return a two dimentional array of eobs
  #first dimension represents the object used for grouping, resulting in one output file per element
  #second dimension represents the checks and eobs in each output file
  def segregate(batch_id,eob_groups)
    eobs = eob_groups
    @batch = Batch.find(:first,:conditions=>"id = #{batch_id}")
    eobs = eobs.delete_if {|c| c.check_information.job.incomplete?}
    check_eob = {}
    eobs.each do |eob|
      check_id = eob.check_information_id
      file_name = group_name(eob,@batch)
      check_eob[file_name] = {} unless check_eob.key?file_name
      check_eob[file_name].merge!({check_id => []}) unless check_eob[file_name].key?check_id
      check_eob[file_name][check_id] << eob
    end
    return check_eob
  end

  # Returns the computed group name for a eob
  # by applying the grouping passed to it
  # group name also depends on certain other parameters
  # configured for a facility
  def group_name(eob,batch)
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
      "#{financial_class_value}#{batch_date}#{batch.cut}_#{batch.index_batch_number.slice(0,3)}_#{batch_type}_#{eob.payer_indicator}"
    else
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
end
