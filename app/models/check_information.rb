# -*- coding: utf-8 -*-
require 'OCR_Data'
include OCR_Data
class CheckInformation < ActiveRecord::Base
  include DcGrid
  include OutputCheckInformation
  
  attr_accessor :style,:coordinates, :page
  before_validation :strip_whitespace
  validates :check_number, :check_amount, presence: true
  validates :check_number, :format => { :with => /^[a-zA-Z0-9_]*$/,
    :message => "Only alphanumeric and underscore allowed" }
  validates :check_amount, numericality: true
  has_many :insurance_payment_eobs, :class_name => "InsurancePaymentEob", :dependent => :destroy
  has_many :service_payment_eobs, :through => :insurance_payment_eobs
  belongs_to :job
  belongs_to :payer
  belongs_to :micr_line_information
  has_many :patient_pay_eobs, :dependent => :destroy
  has_many :reason_codes
  has_one :report_check_information, :dependent => :destroy
  has_many :ordered_insurance_eobs, :class_name => 'InsurancePaymentEob', :order => ["image_page_no, end_time asc"]
  has_many :ordered_patient_pay_eobs, :class_name => 'PatientPayEob', :order => ["image_page_no, end_time asc"]

  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details"
  has_details :check_amount,
    :check_number,
    :provider_adjustment_amount,
    :check_date,
    :check_sequence

  before_save do |obj|
    obj.set_correspondence_check_number
    obj.upcase_grid_data(['details','guid', 'payment_type'])
  end

  after_update :create_qa_edit
  def create_qa_edit
    QaEdit.create_records(self)
  end
 
  # Generates the GUID and sets it as default value
  default_value_for :guid do
    UUID.new.generate
  end

  scope :by_batch, lambda{ |batch_ids| {:conditions => ["jobs.batch_id IN (?)", batch_ids], :include => [:job]}}
  scope :get_qualified_checks, lambda{ |batch_ids| {:conditions => 
        ["jobs.batch_id IN (?) and jobs.is_excluded = 0 and (jobs.job_status = '#{JobStatus::COMPLETED}'
           or jobs.job_status = '#{JobStatus::INCOMPLETED}')", batch_ids], :include => [:job]}}
  scope :get_completed_checks, lambda{ |batch_ids| {:conditions =>
        ["jobs.batch_id IN (?) and jobs.is_excluded = 0 and jobs.job_status = '#{JobStatus::COMPLETED}'",
        batch_ids], :include => [:job]}}
  scope :get_exception_checks, lambda{ |batch_ids| {:conditions =>
        ["jobs.batch_id IN (?) and jobs.job_status = '#{JobStatus::INCOMPLETED}'", batch_ids], :include => [:job]}}


  # Provides the CheckInformation object for parent or a sub job.
  #  If the job is a split job, it will have a parent_job_id
  # Input :
  # job_id : id of the job object
  # Output :
  # check_information : CheckInformation object

  def self.check_information(job_id)
    check_information = CheckInformation.find_by_job_id(job_id)
    unless check_information.blank?
      check_information
    else
      parent_job_id = Job.find(job_id).parent_job_id
      check_information = CheckInformation.find_by_job_id(parent_job_id)
    end
  end

  def self.check_number_value(job_id)
    check_number = Job.find(job_id).check_number
    check_number
  end

  def set_correspondence_check_number
    self.check_number = "000000" if correspondence? and $IS_PARTNER_BAC
  end

  #This will return the stle for an OCR data, depending on its origin
  #4 types of origins are :
  #0 = imported from 837
  #1= read by OCR with 100% confidence (questionables_count =0)
  #2= read by OCR with < 100% confidence (questionables_count >0)
  #3= blank data
  #column  is the name of the database column of which you want to get the style
  def style(column)
    method_to_call = "#{column}_data_origin"
    begin
      case self.details[method_to_call.to_sym]
      when OCR_Data::Origins::IMPORTED
        "ocr_data imported"
      when OCR_Data::Origins::CERTAIN
        "ocr_data certain"
      when OCR_Data::Origins::UNCERTAIN
        "ocr_data uncertain"
      when OCR_Data::Origins::BLANK
        "ocr_data blank"
      else
        "ocr_data blank"
      end
    rescue NoMethodError
      # Nothing matched, assign default
      OCR_Data::Origins::BLANK
    end
  end

  #This will return the coordinates for an OCR'd field
  #OCR  engine returns the coordinates in terms of
  # top, bottom, left and right, in that order
  def coordinates(column)
    method_to_call = "#{column}_coordinates"
    begin
      coordinates = self.details[method_to_call.to_sym]
      coordinates_appended = ""
      coordinates.each do |coordinate|
        coordinates_appended += "#{coordinate} ,"
      end
      coordinates_appended
    rescue NoMethodError
      # Nothing matched, send nil object so that the attribute in the view it will be dropped
      nil
    end
  end

  #This will return the page number on the image of an OCR'd field
  def page(column)
    method_to_call = "#{column}_page"
    begin
      self.details[method_to_call.to_sym]
    rescue NoMethodError
      # Nothing matched, send nil object so that the attribute in the view it will be dropped
      nil
    end
  end
  
  def nextgen_check?
    # EOBs processed in nextgen grid will have no payer
    # they will be stored in patient_pay_eobs table
    # nextgen grid is rendered only when specified so, thru FC UI
    (!self.patient_pay_eobs.blank? &&
        self.batch.facility.patient_pay_format == 'Nextgen Format')
  end

  # Returns whether a check is correspondance check
  def correspondence?(batch = nil, facility = nil)
    batch ||= job.batch if job
    facility ||= batch.facility if batch
    is_system_generated_check_number = has_system_generated_check_number?(batch, facility)
    if !check_amount.blank? && payment_method.to_s.upcase != 'EFT' && (!check_number.blank? || is_system_generated_check_number)
      check_amount.to_f.zero? && (check_number.to_f.zero? || is_system_generated_check_number)
    else
      true
    end
  end

  def client_specific_payer_name(facility)
    payer_name = nil
    if facility.details["custom_payer_name_in_op"] and !micr_line_information_id.blank?
      custom_payer_name=FacilitiesMicrInformation.where(:facility_id => facility.id,:micr_line_information_id => micr_line_information_id).first
      if !custom_payer_name.blank?
        payer_name = custom_payer_name.onbase_name
      end
    end
    return payer_name
  end

  def client_specific_payer_id(facility)
    payer_id_value = nil
    if facility.details["custom_payer_id_in_op"] and !payer_id.blank?
      custom_payer_id=FacilitiesPayersInformation.where(:facility_id => facility.id,:payer_id => payer_id).first
      if !custom_payer_id.blank?
        payer_id_value = custom_payer_id.output_payid
      end
      return payer_id_value
    end
  end


  # Returns the batch corresponding to the check
  def batch
    job && job.batch
  end

  # Formats a dollar amount that is to be printed in the output
  # returns the amount if present else returns 0
  def amount(col_name)
    amount = send(col_name).to_f
    (amount == amount.truncate) ? amount.truncate : amount
  end

  # The method 'total_payment_amount' returns the total payment for this check
  def total_payment_amount
    sum = 0.00
    unless self.insurance_payment_eobs.blank?
      self.insurance_payment_eobs.each do |eob|
        (sum = sum + eob.total_amount_paid_for_claim) unless eob.total_amount_paid_for_claim.nil?
      end
    end
    sum
  end

  # This is for getting 'total_copay_amount' within a transaction
  def total_copay_amount
    sum = self.insurance_payment_eobs.sum(:total_co_pay)
    sum.to_f
  end
    
  def total_copay_amount_old
    sum = 0.00
    unless self.insurance_payment_eobs.blank?
      self.insurance_payment_eobs.each do |eob|
        (sum = sum + eob.total_co_pay) unless eob.total_co_pay.nil?
      end
    end
    sum
  end
  
  def get_amount_so_far
    patient_payment_eob_count = PatientPayEob.count(:conditions => "check_information_id = #{id}")
    if patient_payment_eob_count != 0
      amount_so_far =  PatientPayEob.amount_so_far(id)
    else
      facility = job.batch.facility
      amount_so_far = InsurancePaymentEob.amount_so_far(self, facility)
    end
    amount_so_far
  end
  
  def get_check_info_id()
    parent_job_id = job.parent_job_id
    if (parent_job_id.blank?)
      check_info = CheckInformation.where(:job_id => job).select(:id).first
      check_info_id = check_info.id if check_info
    else
      check_info = CheckInformation.where(:job_id => parent_job_id).select(:id).first
      check_info_id = check_info.id if check_info
    end
    check_info_id
  end
  # The method 'any_eob_processed?' is a Predicate Method.
  # The method 'any_eob_processed?' returns true if the check contains more than one saved EOB.
  # This is used where the 'transaction_type' needs to disabled from the 2nd EOB onwards for the check.
  # For Multi tiff image & 'Processor view', 'transaction_type' is saved only for the first EOB, because it is same for all images.
  def any_eob_processed?
    self.insurance_payment_eobs.length >= 1
  end

  # Determines whether the check have patient payer
  # Input :
  # facility : facility of the check
  # Output :
  # true if is a patient payer else false
  def does_check_have_patient_payer?(facility_obj = nil, payer_obj = nil)
    facility = facility_obj
    if job
      if facility.blank?
        facility = job.batch.facility
      end
      case job.payer_group
      when 'Insurance'
        is_pat_pay_eob = false
      when 'PatPay'
        is_pat_pay_eob = true
      else
        is_pat_pay_eob = nil
      end
    end
    if is_pat_pay_eob.nil?
      payer_obj ||= payer
      is_pat_pay_eob = (payer_obj.supply_payid == facility.patient_payerid if payer_obj && facility)
    end
    is_pat_pay_eob
  end

  def eob_type(facility = nil)
    is_pat_pay_eob = does_check_have_patient_payer?(facility)
    is_pat_pay_eob ? 'Patient' : 'Insurance'
  end
  
  # Calculating processor_input_field_count in check level
  # by checking constant fields in grid as well as configured fields populated through FCUI.
  def processor_input_field_count(facility, eob_type)
    total_field_count_with_data = 0
    configured_fields = []
    constant_fields = [check_amount, check_number, payment_method]
    fc_ui_date_fields = [check_mailed_date, check_received_date]
    
    if eob_type == 'nextgen'
      #      Adding all the two check amount fields in the NextGen grid.
      selected_fields = [check_amount]
    else
      selected_fields = [check_date]
    end

    configured_fields << payment_type if facility.details[:payment_type]
    configured_fields << alternate_payer_name if facility.details[:re_pricer_info]
    total_field_array = constant_fields + configured_fields + selected_fields +
      fc_ui_date_fields
    total_field_array_with_data = total_field_array.select{|field| !field.blank?}
    total_field_count_with_data = total_field_array_with_data.length
    total_field_count_with_data
  end
  
  def get_image_name
    image_file_name = ""
    facility_image_type = facility.image_type
    client_images_to_job = ClientImagesToJob.find(:first,
      :select => "client_images_to_jobs.images_for_job_id as images_for_job_id,
                    images_for_job.image_file_name as image_file_name",
      :conditions => ["client_images_to_jobs.job_id = ?", job.id],
      :include => :images_for_job)
    if (facility_image_type == 0)
      image_file_name = client_images_to_job.images_for_job.exact_file_name if (client_images_to_job)
    elsif (facility_image_type == 1)
      image_file_name = client_images_to_job.images_for_job.image_file_name if (client_images_to_job)
    end
    image_file_name
  end

  # This method returns the image name of the check
  def image_file_name
    if job.images_for_jobs.first.is_splitted_image == true
      job.images_for_jobs.first.exact_file_name rescue nil
    else
      job.images_for_jobs.first.filename rescue nil
    end
  end

  def facility
    self.job.batch.facility
  end

  def eobs
    insurance_payment_eobs if insurance_payment_eobs
  end  
  
  def eob_image_page_numbers
    eob_image_page_numbers = []
    insurance_payment_eobs.map{|eob| eob_image_page_numbers << eob.image_page_no}
    insurance_payment_eobs.map{|eob| eob_image_page_numbers << eob.image_page_to_number if eob.image_page_to_number}
    eob_image_page_numbers.compact.uniq
  end

  # Returns the EDC Transaction XML body, without the header and footer.
  def tran_xml(xml, index, job, batch, transaction_set_count)    
    if !payer.blank? && !payer.status.blank? && (!payer.gateway.blank? || !payer.gateway_temp.blank?)
      gateway = payer.status.upcase == 'MAPPED' ? payer.gateway : (payer.gateway_temp || 'HLSC')
      payid = payer.payer_identifier(micr_line_information)
      footnote_indicator = (payer.footnote_indicator ? 1 : 0)
    else raise 'Invalid Payer'
      puts "Payer record for check number #{check_number} is incomplete or invalid"
      log.error "Payer record for check number #{check_number} is incomplete or invalid"
    end

    payee_name ||= batch.facility.name.to_s.strip
    xml.tran(:ID => index + 1) do
      xml.tag!(:batch_attrib, 1)
      xml.tag!(:gateway, gateway)
      xml.tag!(:pay_id, payid)
      xml.tag!(:payee_nm, (payee_name.slice(0, 25) if !payee_name.blank?))
      xml.tag!(:aba_num, (micr_line_information.aba_routing_number if micr_line_information))
      xml.tag!(:chk_act, (micr_line_information.payer_account_number if micr_line_information))
      xml.tag!(:chk_num, check_number)
      xml.tag!(:chk_amt, sprintf('%.02f', check_amount.to_f))
      xml.tag!(:eob_id, (index + 1))
      xml.tag!(:tid, job.transaction_number)
      xml.tag!(:rework, '0')
      xml.tag!(:payer_footnote_based, (footnote_indicator || 0))
      xml.tag!(:worklist_status_cd, '')
      xml.tag!(:transaction_receipt_dt, (batch.date.strftime("%Y-%m-%d") unless batch.date.blank?))
      xml.tag!(:hlsc_file_nm, batch.src_file_name)
      xml.tag!(:show_on_worklist, '0')
      xml.tag!(:transaction_guid, guid)
    end
    transaction_set_count += 1
  end
    
  def doc_xml(xml, index, doc_set_count)
    job.images_for_jobs.each do |image|
      file_name = image.filename
      extn = File.extname(file_name) if file_name
      xml.doc(:ID => doc_set_count + 1) do
        xml.tag!(:tran_attrib, index + 1)
        xml.tag!(:doc_cont_cd, image.image_type_for_transaction)
        xml.tag!(:subtype_cd, (extn.slice(1, extn.length + 1).upcase unless extn.blank?))
        xml.tag!(:filename, file_name)
        xml.tag!(:pnc_tif, file_name)
        xml.tag!(:file_size, image.size)
      end
      doc_set_count += 1
    end

    eob_ids = eobs.map(&:id)
    hr_eob_output_files = OutputActivityLog.all(:conditions => ["file_format = ? \
                          and batch_id = ? and eobs_output_activity_logs.insurance_payment_eob_id IN (?)",
        'HREOB', job.batch_id, eob_ids],
      :include => :eobs_output_activity_logs)
    hr_eob_output_files.each do |hreob|
      file_name = hreob.file_name
      extn = File.extname(file_name) if file_name
      xml.doc(:ID => doc_set_count + 1) do
        xml.tag!(:tran_attrib, index + 1)
        xml.tag!(:doc_cont_cd, 'EOB')
        xml.tag!(:subtype_cd, 'PLN')
        xml.tag!(:filename, file_name)
        xml.tag!(:pnc_tif, file_name)
        xml.tag!(:file_size, hreob.file_size)
      end
      doc_set_count += 1
    end
     
    doc_set_count
  end

  
  def date_in_checks(date_value)
    if date_value.blank?
      "mm/dd/yy"
    else
      date_value.strftime("%m/%d/%y")
    end
  end
  
  # Indicates whether the balance record exist for the check.
  # Returns true if any EOB of the check contains a valid balance record type else false.
  def balance_record_eob_exist?
    insurance_payment_eobs.count(:conditions => ['balance_record_type is not NULL']) > 0
  end

  def get_payer
    micr_line = micr_line_information
    if micr_line && micr_line.payer
      micr_line.payer
    elsif payer
      payer
    end
  end

  def self.count_of_unfinished_checks_for_payer(payer_id)
    micr_line_informations = MicrLineInformation.find(:all,
      :conditions => ['payer_id = ?', payer_id], :select => ['id'])
    micr_ids = micr_line_informations.map(&:id)
    self.count(:all, :include => [:job],
      :conditions => ["jobs.job_status != ? and jobs.job_status != ? and jobs.job_status != ? and
        (check_informations.micr_line_information_id in (?) or check_informations.payer_id = ?)",
        JobStatus::COMPLETED, JobStatus::EXCLUDED, JobStatus::INCOMPLETED, micr_ids, payer_id])
  end

  #change the payer associated for the checks from the micr
  def self.update_payer_of_check_information micr
    if micr.payer
      micr.reload
      self.where(:micr_line_information_id => micr.id).update_all(:payer_id => micr.payer.id, :updated_at => Time.now)
      logger.debug "Updating the Check Information with the new payer"
      return true
    else
      return false
    end
  end

  # +--------------------------------------------------------------------------+
  # This method determines whether to display Patient Pay grid by default or not.
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR(Check has no MICR)/ New MICR(Check has MICR with status as 'New')/
  #    MICR does not belong to Insurance Payer(Check’s Payer and MICR’s Payer are
  #    the same and payer's payer_type = ‘PatPay’).                             |
  # 2) Check number length(after trimming the left padded zeroes) = 4.         |
  # +--------------------------------------------------------------------------+
  def display_patpay_grid_by_default?(client_name, facility, job_payer_group)
    if (client_name == 'GOODMAN CAMPBELL' && !facility.patient_payerid.blank? && facility.patient_pay_format == "Nextgen Format")
      case job_payer_group
      when 'Insurance'
        is_patpay = false
      when 'PatPay'
        is_patpay = false
      else
        is_patpay = nil
      end
    else
      case job_payer_group
      when 'Insurance'
        is_patpay = false
      when 'PatPay'
        is_patpay = true
      else
        is_patpay = nil
      end
    end
    if is_patpay.nil?
      unless check_number.blank?
        check_number_after_trimming_the_left_padded_zeroes = check_number.to_s.gsub(/^[0]+/, '')
      end
      new_micr = (micr_line_information && micr_line_information.status == "New")
      no_micr = micr_line_information_id.blank?
      insurance_payer = payer && payer.payer_type != "PatPay"
      patient_payer_micr = (micr_line_information && micr_line_information.payer &&
          micr_line_information.payer.payer_type == "PatPay")
      micr_with_no_payer = micr_line_information && micr_line_information.payer.blank?
      unless check_number_after_trimming_the_left_padded_zeroes.blank?
        facility_settings_for_patpay = !facility.blank? && !facility.patient_payerid.blank?

        is_patpay = facility_settings_for_patpay && !insurance_payer &&
          check_number_after_trimming_the_left_padded_zeroes.length == 4 &&
          ((new_micr && (patient_payer_micr || micr_with_no_payer)) || no_micr)
      end
    end
    is_patpay
  end

  def self.checks_batch_ids checks
    check_ids = checks.collect(&:id)
    sql = "SELECT DISTINCT j.batch_id from check_informations c  INNER JOIN jobs j ON c.job_id = j.id WHERE "
    sql << " c.id in (#{check_ids.join(",")}) "
    find_by_sql(sql).collect(&:batch_id)
  end

  def payer_type
    begin
      if self.nextgen_check?
        'notapplicable'
      else
        (job.payer_group == 'PatPay' ? "patient_pay" : "insurance_pay")
      end
    rescue Exception => e
      raise "Payer is missing for check : #{check_number}, id : #{id}"
    end
  end

  
  def populate_report_check_informations(is_insurance_pay, batch_id, job_id, facility)
    eobs = self.insurance_payment_eobs.includes(:mpi_statistics_reports)
    total_indexed_amount = 0
    total_interest_amount = 0
    total_eobs_with_mpi_success = 0
    total_eobs_with_mpi_failure = 0
    if !eobs.blank?
      selected_eob_values = eobs.select("count(*) as total_eobs,
        sum(total_amount_paid_for_claim) as total_paid_amount,
        sum(claim_interest) as interest_amount").first

      total_interest_amount = selected_eob_values.interest_amount.to_f if !facility.details[:interest_in_service_line]
      total_indexed_amount = selected_eob_values.total_paid_amount.to_f + total_interest_amount.to_f
      total_eobs_with_mpi_success = eobs.map {|eob| eob.mpi_statistics_reports}.flatten.select {|mpi_statistics_report| mpi_statistics_report.mpi_status == 'Success'}.length
      total_eobs_with_mpi_failure = eobs.map {|eob| eob.mpi_statistics_reports}.flatten.select {|mpi_statistics_report| mpi_statistics_report.mpi_status == 'Failure'}.length
      check_id = id
      report_check_information = ReportCheckInformation.update_all(
        "total_indexed_amount = '#{total_indexed_amount}',
          total_eobs = #{selected_eob_values.total_eobs.to_i},
          total_eobs_with_mpi_success = #{total_eobs_with_mpi_success},
          total_eobs_with_mpi_failure = #{total_eobs_with_mpi_failure},
          is_self_pay = #{is_insurance_pay}",
        "batch_id = '#{batch_id}' && job_id = '#{job_id}' &&
          check_information_id = '#{check_id}'")
    
      if report_check_information == 0
        report_check_information = ReportCheckInformation.create(
          :batch_id => batch_id,
          :job_id => job_id,
          :check_information_id => check_id,
          :total_indexed_amount => total_indexed_amount,
          :total_eobs => selected_eob_values.total_eobs.to_i,
          :total_eobs_with_mpi_success => total_eobs_with_mpi_success,
          :total_eobs_with_mpi_failure => total_eobs_with_mpi_failure,
          :is_self_pay => is_insurance_pay)
      end
    end
  end

  def nextgen_eobs_for_goodman
    insurance_payment_eobs.select{|eob| !eob.old_eob_of_goodman?}
  end

  def old_eobs_for_goodman
    insurance_payment_eobs.select{|eob| eob.old_eob_of_goodman?}
  end

  def provider_adjustment_amount
    job.get_all_provider_adjustments.collect{|provider_adj| provider_adj.amount.to_f}.sum
  end

  def eob_amount_calculated(eobs, nextgen_insu_flag)
    payment_amount =  eobs.collect{ |eob| eob.total_amount_paid_for_claim.to_f}.sum
    interest_amount = eobs.collect{|eob| eob.claim_interest.to_f}.sum
    provider_adjustment_amount_val = provider_adjustment_amount
    if !nextgen_eobs_for_goodman.blank?
      if nextgen_insu_flag
        eob_amount_value = payment_amount + interest_amount + provider_adjustment_amount_val
      else
        eob_amount_value = payment_amount + interest_amount
      end
    else
      eob_amount_value = payment_amount + interest_amount + provider_adjustment_amount_val
    end
    eob_amount_value
  end
 

  # Provides the total paid amount for a check
  # Input :
  #  facility : facility of the check
  # Output :
  # total_paid_amount : Decimal value rounded to 2 decimal points
  def total_paid_amount(facility)
    eobs = InsurancePaymentEob.select("SUM(total_amount_paid_for_claim) AS total_payment, \
       SUM(claim_interest) AS total_interest, \
       SUM(late_filing_charge) AS total_filing_charge, \
       SUM(fund) AS total_fund, \
       SUM(over_payment_recovery) AS total_over_payment_recovery").
      where("check_information_id = #{id}")
    eob = eobs.first if !eobs.blank?
    if !eob.blank?
      total_over_payment_recovery = facility.details[:over_payment_recovery] ? eob.total_over_payment_recovery : 0
      payment_amount = eob.total_payment.to_f
      net_payment_amount = payment_amount.to_f - total_over_payment_recovery.to_f
      total_paid_amount = net_payment_amount.to_f + eob.total_filing_charge.to_f + eob.total_fund.to_f
      if !facility.details[:interest_in_service_line]
        total_paid_amount += eob.total_interest.to_f
      end
    else
      total_paid_amount = PatientPayEob.where("check_information_id = #{id}").sum('stub_amount')
    end
    job_ids = job.job_ids_for_check
    if !job_ids.blank?
      total_provider_amount = ProviderAdjustment.where("job_id in (#{job_ids.join(',')})").sum('amount')
    end
    total_paid_amount += total_provider_amount.to_f
    total_paid_amount.to_f.round(2)
  end

  # This predicate method see if the check is balanced to paid amount or not
  # Input :
  #  facility : facility of the check
  # Output :
  #  True if the check is balanced, else false
  def is_check_balanced?(job, facility = nil)
    facility ||= job.batch.facility if job
    total_paid_amount = total_paid_amount(facility)
    total_paid_amount -= get_total_payment_of_interest_eob
    balance = (check_amount.to_f.round(2)) - (total_paid_amount.to_f.round(2))
    if balance.zero? || !job.parent_job_id.blank?
      true
    else
      false
    end
  end

  # Apredicate method that see if the transaction type for the check is Missing Check or is Check Only
  def is_transaction_type_missing_check_or_check_only?
    found_desired_transaction_type = false
    transaction_type = get_transaction_type
    if transaction_type == 'Missing Check' || transaction_type == 'Check Only'
      found_desired_transaction_type = true
    end
    found_desired_transaction_type
  end

  # Returns the transaction_type for the check
  def get_transaction_type
    images_for_job = job.images_for_jobs.select(:transaction_type).first
    images_for_job.transaction_type unless images_for_job.blank?
  end
  
  def get_total_claim_interest
    InsurancePaymentEob.sum(:claim_interest, :conditions => "check_information_id = #{self.id} and  claim_interest != ''")
  end

  def auto_generate_check_number(batch = nil)
    batch ||= job.batch if job
    facility ||= batch.facility if batch
    client ||= facility.client if facility
    is_client_ascend_clinical = (!client.blank? && client.name == "ASCEND CLINICAL LLC")

    is_client_quadax = (!client.blank? && client.name.upcase == "QUADAX")
    is_client_barnabas = (!client.blank? && client.name.upcase == "BARNABAS")
    is_client_qsi = (!client.blank? && client.name.upcase == "PACIFIC DENTAL SERVICES")
    check_amt_equals_zero_condn = (check_amount.to_f == 0)
    check_amt_greater_than_zero_condn = (check_amount.to_f > 0)
    check_num_equals_zero_condn = (check_number.to_i == 0)
    payment_method_cor_condn = (payment_method == "COR")
    payment_method_eft_condn = (payment_method == "EFT")

    denial_condition = (does_check_have_patient_payer?(facility) ? (total_payment_amount.zero? && total_copay_amount.zero?) : is_denial_transaction?)
    is_check_number_auto_generated = is_check_number_in_auto_generated_format?(check_number, batch, is_client_ascend_clinical, is_client_quadax, is_client_qsi)

    condition_for_ascend_clinical_llc = (is_client_ascend_clinical &&
        ((payment_method_cor_condn && (check_amt_equals_zero_condn || denial_condition)) ||
          (payment_method_eft_condn && check_amt_greater_than_zero_condn)))

    condition_for_quadax = (is_client_quadax &&
        ((payment_method_cor_condn && check_amt_equals_zero_condn && check_num_equals_zero_condn) ||
          (payment_method_eft_condn && check_amt_greater_than_zero_condn && check_num_equals_zero_condn)))
    
    condition_for_barnabas = (payment_method_cor_condn &&
        denial_condition && is_client_barnabas)

    condition_for_qsi = (is_client_qsi &&
        ((payment_method_cor_condn && (check_amt_equals_zero_condn || denial_condition)) ||
          (payment_method_eft_condn && check_amt_greater_than_zero_condn && check_num_equals_zero_condn)))

    if condition_for_ascend_clinical_llc
      self.check_number = generate_check_number_for_ascend_clinical_llc if (!is_check_number_auto_generated && check_num_equals_zero_condn)
    elsif condition_for_quadax
      if payment_method_cor_condn
        self.check_number = generated_check_number_without_timestamp(batch) + Time.now.strftime('%H%M%S') unless is_check_number_auto_generated
      elsif payment_method_eft_condn
        self.check_number = generated_check_number_without_timestamp_for_quadax_eft(batch) + Time.now.strftime('%H%M%S') unless is_check_number_auto_generated
      end
    elsif condition_for_barnabas
      self.check_number = generated_check_number_without_timestamp(batch) + Time.now.strftime('%H%M%S') unless is_check_number_auto_generated
    elsif condition_for_qsi
      self.check_number = generate_check_number_for_qsi unless is_check_number_auto_generated
    else
      self.check_number = 0 if is_check_number_auto_generated
    end
    self.save
  end

  def is_denial_transaction?
    non_denied_eobs = insurance_payment_eobs.select {|e| e.claim_type_weight != 4}
    non_denied_eobs.empty? ? true : false
  end

  def has_system_generated_check_number?(batch = nil, facility = nil)
    batch ||= job.batch if job
    facility ||= batch.facility if batch
    client ||= facility.client if facility
    is_client_present = (!client.blank?)
    client_name = client.name.upcase if is_client_present
    is_client_ascend_clinical_llc = (is_client_present && client_name == "ASCEND CLINICAL LLC")
    is_client_quadax = (is_client_present && client_name == "QUADAX")
    is_client_barnabas = (is_client_present && client_name == "BARNABAS")
    is_client_qsi = (is_client_present && client_name == "PACIFIC DENTAL SERVICES")

    check_amt_equals_zero_condn = (check_amount.to_f == 0)
    check_amt_greater_than_zero_condn = (check_amount.to_f > 0)
    check_num_equals_zero_condn = (check_number.to_i == 0)
    payment_method_cor_condn = (payment_method == "COR")
    payment_method_eft_condn = (payment_method == "EFT")

    result = false
    denial_condition = (does_check_have_patient_payer?(facility) ? (total_payment_amount.zero? && total_copay_amount.zero?) : is_denial_transaction?)
    condition_for_quadax = (is_client_quadax &&
        ((payment_method_cor_condn && check_amt_equals_zero_condn && check_num_equals_zero_condn) ||
          (payment_method_eft_condn && check_amt_greater_than_zero_condn && check_num_equals_zero_condn)))

    condition_for_qsi = (is_client_qsi &&
        ((payment_method_cor_condn && (check_amt_equals_zero_condn || denial_condition)) ||
          (payment_method_eft_condn && check_amt_greater_than_zero_condn && check_num_equals_zero_condn)))

    if ((payment_method_cor_condn && ((is_client_barnabas && denial_condition) ||
              (is_client_ascend_clinical_llc && (denial_condition || check_amt_equals_zero_condn )))) ||
          (is_client_ascend_clinical_llc && payment_method_eft_condn && check_amt_greater_than_zero_condn) ||
          (condition_for_quadax) || (condition_for_qsi))
      
      result = is_check_number_in_auto_generated_format?(check_number, batch, is_client_ascend_clinical_llc, is_client_quadax, is_client_qsi)
    end
    
    result
  end

  def generated_check_number_without_timestamp(batch = nil)
    batch ||= job.batch if job
    'RX' + batch.date.strftime('%d%m%y') if batch
  end

  def generated_check_number_without_timestamp_for_quadax_eft(batch = nil)
    batch ||= job.batch if job
    'RM' + batch.date.strftime('%d%m%y') if batch
  end

  def is_check_number_in_auto_generated_format?(check_number, batch, is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    batch ||= job.batch if job
    is_check_number_auto_generated = false
    if !is_client_ascend_clinical && !is_client_qsi &&
        (check_number.to_s.start_with?('RX') || check_number.to_s.start_with?('RM'))
      check_number_without_time_stamp = check_number[0 ... -6]
      time_stamp_in_check_number = check_number[-6 .. -1]
      if is_client_quadax && check_amount.to_f > 0
        generated_check_number_without_time = generated_check_number_without_timestamp_for_quadax_eft(batch)
      else
        generated_check_number_without_time = generated_check_number_without_timestamp(batch)
      end
      is_check_number_auto_generated = (check_number_without_time_stamp == generated_check_number_without_time &&
          !time_stamp_in_check_number.blank? && time_stamp_in_check_number.match(/([0-1]{1}\d{1}|[2][0-3]{1})[0-5]{1}\d{1}[0-5]{1}\d{1}/) != nil)
    elsif is_client_ascend_clinical && check_number.to_s.start_with?('REVMEDNOPAY') && !is_client_qsi
      sequence_number = check_number[11, 7].to_i
      sequence_number = sequence_number.to_s
      is_check_number_auto_generated = (sequence_number != "0" && sequence_number.match(/\d{1,7}/) != nil)
    elsif is_client_qsi && check_number.to_s.start_with?('SL')
      sequence_number = check_number[2, 10].to_i
      sequence_number = sequence_number.to_s
      is_check_number_auto_generated = (sequence_number != "0" && sequence_number.match(/\d{1,10}/) != nil)
    end unless check_number.blank?
    is_check_number_auto_generated
  end

  def generate_check_number_for_ascend_clinical_llc
    next_sequence_number =  Sequence.get_next("ASCEND_CLINICAL_LLC")
    "REVMEDNOPAY" + ("%07d" % next_sequence_number)
  end

  def generate_check_number_for_qsi
    next_sequence_number =  Sequence.get_next("PACIFIC DENTAL SERVICES")
    "SL" + ("%010d" % next_sequence_number)
  end
  
  def get_eob_count
    eob_count_value = job.eob_count
    if eob_count_value == 0
      insurance_eob_count = eobs.count
      eob_count_value = (insurance_eob_count != 0 ? insurance_eob_count : patient_pay_eobs.count)
    end
    eob_count_value
  end

  def interest_only_eob_id(client_name)
    client_name ||= job.batch.facility.client.name
    eobs = insurance_payment_eobs
    if eobs.length == 1 && client_name.upcase == 'MEDISTREAMS'
      eob = eobs.first
      if eob.balance_record_type == 'INTEREST ONLY'
        interest_only_eob_id = eob.id
      end
    end
    interest_only_eob_id
  end

  def get_total_payment_of_interest_eob
    count_of_eobs = InsurancePaymentEob.count(:conditions => "check_information_id = #{id}")
    if count_of_eobs > 1
      interest_eob = InsurancePaymentEob.select(:total_amount_paid_for_claim).where(:check_information_id => id, :balance_record_type => 'INTEREST ONLY').first
      #interest_eob = interest_eobs.first unless interest_eobs.blank?
      if !interest_eob.blank?
        interest_eob_payment = interest_eob.total_amount_paid_for_claim
      end
    end
    interest_eob_payment.to_f
  end

  def get_actual_payer_type(job_payer_group)
    begin
      if self.nextgen_check?
        'NextGen'
      elsif(job_payer_group == 'PatPay')
        'Patient Pay'
      elsif(job_payer_group == 'Commercial')
        'Commercial'
      else
        'Insurance'
      end
    rescue Exception => e
      raise "Payer is missing for check : #{check_number}, id : #{id}"
    end
  end

  def get_actual_payid(facility, job_payer_group, orbograph_correspondence_condition)
    if(job_payer_group == 'PatPay')
      facility.patient_payerid
    else
      if (orbograph_correspondence_condition)
        ""
      else
        payer.payid
      end
    end
  end

  def get_image_file_name_with_extn
    final_image_file_name = ""
    image_name = job.images_for_jobs.first.exact_file_name unless job.images_for_jobs.blank?
    unless image_name.blank?
      final_image_file_name = supply_image_extension(image_name)
    end
    final_image_file_name.blank? ? "-" : final_image_file_name
  end

  def supply_image_extension(image_name)
    if File.extname(image_name.upcase) == ".TIF"
      final_image_file_name = image_name
    elsif File.extname(image_file_name.upcase) == ".TIFF"
      final_image_file_name = image_name.gsub(/\.tiff$/i,".tif")
    else
      final_image_file_name = image_name + ".tif"
    end
  end

  def get_actual_image_file_name_with_extn
    final_image_file_name = ""
    image_name = job.initial_image_name unless job.initial_image_name.blank?
    unless image_name.blank?
      final_image_file_name = supply_image_extension(image_name)
    end
    final_image_file_name.blank? ? "-" : final_image_file_name
  end
  
  def strip_whitespace
    self.check_number.to_s.gsub!(/\s+/, "") unless self.check_number.blank?
  end
end
 
