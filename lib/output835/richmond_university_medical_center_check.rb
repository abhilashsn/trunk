
class Output835::RichmondUniversityMedicalCenterCheck < Output835::Check

  def initialize(check, facility, index, element_seperator, check_nums)
    @check = check
    @check_nums = check_nums
    @index = index
    @element_seperator = element_seperator
    # passing check number array also to verify for patpay 
    # whether the check number is repeating
    @eob_type = check.eob_type
    # Circumventing using Check <-> Payer association because of the existing
    # bug in MICR module where it does not update payer_id in check
    # after identifying the payer for a check, while loading grid
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    @facility = facility
    @facility_config = facility.facility_output_configs.first
    @flag = 0
    @client = @facility.client
    init_check_info check unless check.nil?
  end
  
  # In TRN02 segment, usually check number comes. For RUMC, For Patpay it should be 
  # "Check Number+Batch date". If check number duplicates add sequential number.
  #  For ex: "Check Number_1+Batch date"
  def reassociation_trace
    trn_elements = []
    trn_elements << 'TRN'
    trn_elements << '1'
    check_num = "#{check.check_number.to_i}"
    job = check.job
    if payer
      if job.payer_group == "PatPay"
        # checking whether the check_number is duplicated
        # in the whole check number array
        if Output835.element_duplicates?(check_num, @check_nums)
          # get all indexes at which duplicate elements are present
          # then check at what position the current element resides
          # that gives the duplication index as one moves from first to last elem of the array
          # For Ex : array = [a, b, c, c, d, e, f, e, g]
          # all_indices for 'c' would return [2, 3]
          # comparing the current element's index with that, we would get either '0' or '1' depending on
          # whether we're dealing with 'c' in 2nd place or at 3rd place, couting starts from 0th place
          # all_indices for 'e' would return [5, 7]
          counter = Output835.all_indices(check_num, @check_nums).index(index)
          # since counter starts from zero, adding 1 to get the correct count
        end
        check_num << "#{check.batch.date.strftime("%m%d%y")}" unless check_num.blank?
        check_num << "#{counter+1}" if counter
      end
    end
    trn_elements << (check_num.blank? ? "0" : check_num)
    if @check_amount.to_f > 0 && check.payment_method == "EFT"
      unless facility.facility_tin.blank?
        trn_elements <<  '1' + facility.facility_tin
      end
    else
      trn_elements <<  '1999999999'
    end
    trn_elements = Output835.trim_segment(trn_elements)
    trn_elements.join(@element_seperator)
  end
  
end