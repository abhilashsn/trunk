require 'OCR_Data'
require "uuid"
require 'adjustment_reason'

class InsurancePaymentEob < ActiveRecord::Base
  include OCR_Data
  include AdjustmentReason
  include ApplicationHelper
  include OutputInsurancePaymentEob
  
  extend ReasonCodesHelper::ClassMethods
  include EobClientCode
  include DcGrid
  attr_accessor :style,:coordinates, :page
  attr_accessor :coinsurance_adjustment_codes, :contractual_adjustment_codes,
    :copay_adjustment_codes, :deductible_adjustment_codes, :denied_adjustment_codes,
    :discount_adjustment_codes, :noncovered_adjustment_codes, :primary_payment_adjustment_codes,
    :prepaid_adjustment_codes, :pr_adjustment_codes,
    :miscellaneous_one_adjustment_codes, :miscellaneous_two_adjustment_codes
  
  attr_accessor :claim_coinsurance_id, :claim_contractual_id, :claim_copay_id,
    :claim_deductible_id, :claim_denied_id, :claim_discount_id,
    :claim_noncovered_id, :claim_prepaid_id, :claim_patient_responsibility_id,
    :claim_primary_payment_id, :claim_miscellaneous_one_id, :claim_miscellaneous_two_id

  attr_accessor :coinsurance_crosswalked_codes, :contractual_crosswalked_codes,
    :copay_crosswalked_codes, :deductible_crosswalked_codes, :denied_crosswalked_codes,
    :discount_crosswalked_codes, :noncovered_crosswalked_codes, :primary_payment_crosswalked_codes,
    :prepaid_crosswalked_codes, :pr_crosswalked_codes,
    :miscellaneous_one_crosswalked_codes, :miscellaneous_two_crosswalked_codes
  
  has_many :patients
  belongs_to :check_information
  has_many :service_payment_eobs, :include => [:coinsurance_reason_code,
    :contractual_reason_code, :copay_reason_code, :deductible_reason_code,
    :denied_reason_code, :discount_reason_code, :noncovered_reason_code,
    :prepaid_reason_code, :patient_responsibility_reason_code, :primary_payment_reason_code], :dependent => :destroy
  belongs_to :claim_information
  belongs_to :contact_information
  has_many :mpi_statistics_reports, :as => :eob, :dependent => :destroy
  has_many :eob_qas, :conditions => {:eob_type_id => 1}, :foreign_key => "eob_id", :dependent => :destroy
  has_many :image_types, :dependent => :destroy
  has_many :insurance_payment_eobs_reason_codes, :dependent => :destroy
  has_many :reason_codes, :through => :insurance_payment_eobs_reason_codes
  has_many :eobs_output_activity_logs, :dependent => :destroy
  has_many :output_activity_logs, :through => :eobs_output_activity_logs
  has_many :insurance_payment_eobs_ansi_remark_codes, :dependent => :destroy
  has_many :ansi_remark_codes, :through => :insurance_payment_eobs_ansi_remark_codes
  has_many :claim_level_service_lines, :dependent => :destroy
  has_many :provider_adjustments
  
  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details"
  has_details :patient_account_number,
    :patient_last_name,
    :patient_first_name,
    :subscriber_first_name,
    :subscriber_last_name,
    :subscriber_identification_code,
    :claim_number,
    :claim_interest,
    :total_amount_paid_for_claim,
    :provider_npi,
    :provider_tin,
    :provider_organisation,
    :plan_type,
    :patient_middle_initial,
    :patient_suffix,
    :total_submitted_charge_for_claim,
    :rendering_provider_last_name,
    :rendering_provider_first_name,
    :rendering_provider_suffix,
    :rendering_provider_middle_initial,
    :subscriber_middle_initial,
    :subscriber_suffix,
    :drg_code,
    :claim_type,
    :insurance_policy_number,
    :carrier_code,
    :site_level_claim_status
  
  belongs_to :coinsurance_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :coinsurance_reason_code_id
  
  belongs_to :contractual_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :contractual_reason_code_id
  
  belongs_to :copay_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :copay_reason_code_id
  
  belongs_to :deductible_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :deductible_reason_code_id
  
  belongs_to :denied_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :denied_reason_code_id
  
  belongs_to :discount_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :discount_reason_code_id
  
  belongs_to :noncovered_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :noncovered_reason_code_id

  belongs_to :prepaid_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :prepaid_reason_code_id

  belongs_to :patient_responsibility_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :pr_reason_code_id
  
  belongs_to :primary_payment_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :primary_payment_reason_code_id

  belongs_to :miscellaneous_one_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :miscellaneous_one_reason_code_id

  belongs_to :miscellaneous_two_reason_code,
    :class_name => 'ReasonCode',
    :foreign_key => :miscellaneous_two_reason_code_id


  belongs_to :coinsurance_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :coinsurance_hipaa_code_id

  belongs_to :contractual_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :contractual_hipaa_code_id

  belongs_to :copay_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :copay_hipaa_code_id

  belongs_to :deductible_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :deductible_hipaa_code_id

  belongs_to :denied_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :denied_hipaa_code_id

  belongs_to :discount_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :discount_hipaa_code_id

  belongs_to :noncovered_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :noncovered_hipaa_code_id

  belongs_to :prepaid_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :prepaid_hipaa_code_id

  belongs_to :patient_responsibility_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :pr_hipaa_code_id

  belongs_to :primary_payment_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :primary_payment_hipaa_code_id

  belongs_to :miscellaneous_one_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :miscellaneous_one_hipaa_code_id

  belongs_to :miscellaneous_two_hipaa_code,
    :class_name => 'HipaaCode',
    :foreign_key => :miscellaneous_two_hipaa_code_id

  #  belongs_to :sub_job, :class_name => 'Job', :foreign_key => 'sub_job_id'

  has_many :client_activity_logs, :as => :eob
  has_many :claim_validation_exceptions, :as => :eob

  alias_attribute :submitted_charge_amount, :total_submitted_charge_for_claim
  alias_attribute :paid_amount, :total_amount_paid_for_claim
  alias_attribute :coinsurance_amount, :total_co_insurance
  alias_attribute :contractual_amount, :total_contractual_amount
  alias_attribute :copay_amount, :total_co_pay
  alias_attribute :deductible_amount, :total_deductible
  alias_attribute :denied_amount, :total_denied
  alias_attribute :discount_amount, :total_discount
  alias_attribute :noncovered_amount, :total_non_covered
  alias_attribute :prepaid_amount, :total_prepaid
  alias_attribute :patient_responsibility_amount, :total_patient_responsibility
  alias_attribute :primary_payment_amount, :total_primary_payer_amount
  alias_attribute :miscellaneous_one_amount, :miscellaneous_one_adjustment_amount
  alias_attribute :miscellaneous_two_amount, :miscellaneous_two_adjustment_amount

  #validate :presense_of_image_page_to_number_if_facility_is_gcbs
  validate :validate_patient_account_number

  before_save do |obj|
    obj.default_values_uid
    exempted_columns = ['details','claim_type','category','guid','document_classification','alternate_payer_name', 'rejection_comment']
    obj.upcase_grid_data(exempted_columns)
  end
  
  after_update :create_qa_edit
  
  def create_qa_edit
    QaEdit.create_records(self)
  end

  scope :secondary_reason_codes_by_adjustment_reason, lambda { |id, adjustment_reason|
    { :select => ["insurance_payment_eobs_reason_codes.* "],
      :joins => [:insurance_payment_eobs_reason_codes],
      :conditions => ['insurance_payment_eobs_reason_codes.insurance_payment_eob_id = ? AND insurance_payment_eobs_reason_codes.adjustment_reason = ?',
        id, adjustment_reason]}
  }
  
  # Generates the GUID and sets it as default value
  default_value_for :guid do
    UUID.new.generate
  end
  def default_values_uid
    self.uid ||= Sequence.get_next('Eob_uid')
  end
  # :TODO : Eager load the reason code related models while fetching service lines.
  
  scope :by_eob, lambda{ |batch_id| {:conditions => ["batch_id IN (#{batch_id})"], :joins => [:check_information => :job]}}
  
  def to_s
    "Check: #{check_information.check_number} PAN: #{patient_account_number}"
  end

  def disallowed
    return (total_non_covered.to_f+total_discount.to_f+total_denied.to_f+total_contractual_amount.to_f)
  end
   
  def claim_type_code
    if claim_type.strip == "Primary" 
      return 1
    elsif claim_type.strip == "Secondary"
      return 2
    elsif claim_type.strip == "Denial"
      return 4
    elsif claim_type.strip == "Processed as Primary - FAP"
      return 19
    elsif claim_type.strip.upcase == "REVERSAL OF PRIOR PAYMENT"
      return 22  
    else
      if claim_type.strip == "Primary, Forwarded to Additional Payer"
        return 19
      end      
      
    end
  end
  def formatted_from_date
    return self.claim_from_date.to_s.split("-").join
  end
  def formatted_to_date
    return self.claim_to_date.to_s.split("-").join
  end
  def type_of_plan
    if plan_type.strip.upcase == "PPO INCLUDING BCBS" or plan_type.strip.upcase == "PPO"
      return "12"
    elsif plan_type.strip.upcase == "POS"
      return  "13"
    elsif plan_type.strip.upcase == "HMO MEDICARE RISK"
      return  "16"
    elsif plan_type.strip.upcase == "DMO"
      return "17"
    elsif plan_type.strip.upcase == "CHAMPUS"
      return "CH"
    elsif plan_type.strip.upcase == "HMO"
      return "HM"
    elsif plan_type.strip.upcase == "MEDICARE A"
      return "MA"
    elsif plan_type.strip.upcase == "MEDICARE B"
      return "MB"
    elsif plan_type.strip.upcase == "MEDICAID"
      return "MC"
    elsif plan_type.strip.upcase == "WORKER'S COMPENSATION" or plan_type.strip.upcase == "WORKERS COMPENSATION"
      return "WC"
    elsif plan_type.strip.upcase == "AUTOMOBILE MEDICAL"
      return "AM"
    elsif plan_type.strip.upcase == "VETORANS AFFAIRS PLAN" 
      return "VA" 
    elsif !plan_type.blank? and plan_type.strip.upcase!="COMMERCIAL" and plan_type.strip.upcase!="NULL" and plan_type.strip.upcase!="null"
      return plan_type
    end
  end
  
  def identification_code_qual
    if patient_identification_code_qualifier
      qual = patient_identification_code_qualifier.strip.upcase
      if qual == "SSN"
        "34"
      elsif qual == "HIC"
        "HN"
      end
    end
  end

  def self.amount_so_far(check_information, facility)
    amount = 0
    insurance_payment_eob = InsurancePaymentEob.find(:first,
      :conditions => "check_information_id = #{check_information.id}",
      :select => "sum(late_filing_charge) late_filing_charge,
         sum(claim_interest) interest_amount,
         sum(total_amount_paid_for_claim) total_amount, sum(fund) total_fund,
         sum(over_payment_recovery) over_payment_recovery",
      :group => "check_information_id")
    if insurance_payment_eob
      interest_amount = !facility.details[:interest_in_service_line] ? insurance_payment_eob.interest_amount : 0
      over_payment_recovery = facility.details[:over_payment_recovery] ? insurance_payment_eob.over_payment_recovery : 0
      payment_amount = insurance_payment_eob.total_amount.to_f
      net_payment_amount = payment_amount.to_f - over_payment_recovery.to_f
      amount = net_payment_amount + interest_amount.to_f + insurance_payment_eob.late_filing_charge.to_f + insurance_payment_eob.total_fund.to_f
      amount -= check_information.get_total_payment_of_interest_eob
    end
    amount.to_f
  end

  def self.page_number(check_information_id, eob_id)
    insurance_eobs = InsurancePaymentEob.where(["check_information_id = ?", check_information_id]).select(:id)
    id_array = insurance_eobs.map(&:id)
    page = id_array.index(eob_id)
    page = page || 0
    page += 1
    page
  end  
  
  #this will return the sum of all service lines for the corresponding column
  def sum(column)
    amount_columns =  ["service_procedure_charge_amount", "pbid", "service_allowable",
      "drg_amount", "expected_payment", "retention_fees", "service_paid_amount",
      "service_prepaid", "service_no_covered", "denied",  "service_discount", "service_co_insurance",
      "service_deductible",  "service_co_pay", "patient_responsibility",
      "primary_payment", "contractual_amount", "miscellaneous_one_adjustment_amount",
      "miscellaneous_two_adjustment_amount", "miscellaneous_balance"]
    service_lines_total = 0.00
    if(amount_columns.include?column and !self.id.nil? and !self.id.blank?)
      @service_lines = ServicePaymentEob.find(:all , :conditions => "insurance_payment_eob_id = #{self.id} ");
      @service_lines.each do |service_line|
        unless service_line.send("#{column}").nil?
          service_lines_total += service_line.send("#{column}")
        end
      end
    end
    return sprintf("%.2f", service_lines_total) if service_lines_total
  end
  
  #returns the group code if valid, else returns nil
  def group_code(group_code)
    unless (self.send(group_code).blank? || self.send(group_code).strip == "..")
      self.send(group_code).to_s.strip
    else
      nil
    end
  end
  
  def payment_amount_for_output(facility, facility_output_config)
    if !claim_interest.to_f.zero? && !facility.details[:interest_in_service_line] &&
        facility_output_config.details[:interest_amount] == "Add Interest With Payment"
      interest_with_payment_amount = total_amount_paid_for_claim.to_f + claim_interest.to_f
      return (interest_with_payment_amount == interest_with_payment_amount.truncate) ?
        interest_with_payment_amount.truncate : interest_with_payment_amount
    else
      return amount('total_amount_paid_for_claim')
    end
  end
  
  # Returns the amount if exists, else returns 0
  def amount(col_name)
    amount = send(col_name).to_f unless (send(col_name).blank? || send(col_name) == 0.00)
    if amount
      amount = ((amount == amount.truncate) ? amount.truncate : amount)
      amount
    else
      0
    end
  end

  # Returns sum of PR amounts if present, else 0
  def patient_responsibility_amount
    pr = (total_co_insurance.to_f +
        total_deductible.to_f +
        total_co_pay.to_f)

    resp_amount = (pr == pr.truncate) ? pr.truncate : pr
    resp_amount = ("%.2f" %(resp_amount)).to_f
    if $IS_PARTNER_BAC
      return resp_amount.zero? ? "" : resp_amount
    else
      return resp_amount
    end
  end
  
  #This will return the stle for an OCR data, depending on its origin
  #4 types of origins are :
  #0 = imported from 837
  #1= read by OCR with 100% confidence (questionables_count =0)
  #2= read by OCR with < 100% confidence (questionables_count >0)
  #3= blank data
  #param 'columm'  is the name of the database column of which you want to get the style
  def style(column)
    method_to_call = "#{column}_data_origin"
    begin
      case self.details[method_to_call.to_sym]
      when Origins::IMPORTED
        "ocr_data imported"
      when Origins::CERTAIN
        "ocr_data certain"
      when Origins::UNCERTAIN
        "ocr_data uncertain"
      when Origins::BLANK
        "ocr_data blank"
      else
        "ocr_data blank"
      end
    rescue NoMethodError
      # Nothing matched, assign default
      Origins::BLANK
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
  
  # Returns a boolean after comparing
  # all parts of patient name with corresponding
  # parts of subscriber name
  def pt_name_eql_sub_name?
    (patient_last_name == subscriber_last_name &&
        patient_first_name == subscriber_first_name &&
        patient_middle_initial == subscriber_middle_initial &&
        patient_suffix == subscriber_suffix)
  end

  #TODO : Need to refactor - Using Old 835 Code Logic
  # Returns the ID and qualifier needed for printing in NM1*IL seg of 835
  # member id and qualifier are returned if present
  # else nil is returned
  def member_id_and_qualifier
    member_id, qual = nil, nil
    unless subscriber_identification_code.blank?
      member_id = subscriber_identification_code
      qual = 'MI'
    end
    return member_id, qual
  end

  #TODO : Need to refactor - Using Old 835 Code Logic
  # Returns the ID and qualifier to be printed in NM1*QC seg of 835
  # When Pt. and Sub. names are same, member id is returned if present
  # else patient id is returned
  def patient_id_and_qualifier
    pat_id, qual = nil, nil
    member_id = subscriber_identification_code unless subscriber_identification_code.blank?
    patient_id = patient_identification_code unless patient_identification_code_qualifier.to_s == '--'
    
    if pt_name_eql_sub_name? && member_id
      pat_id = member_id
      qual = 'MI'
    else
      pat_id = patient_id
      qual = identification_code_qual
    end
    return pat_id, qual
  end

  def total(total_column, column, patient_837_information, claim_level_eob)
    if claim_level_eob
      return (sprintf("%.2f", self.send(total_column)) unless (self.send(total_column)).blank?)
    else
      return (patient_837_information.blank? ? self.sum(column) : '0.00')
    end
  end
  
  # The method 'claim_reason_codes' returns the reasoncodes of the dollar amount field.
  # It gets two parameters as follows:
  # column - The reason code column name of the field
  # claim_level_eob - The FC parameter set for the Claim Level EOB
  def claim_reason_codes(column, claim_level_eob)
    if claim_level_eob
      return self.send(column) unless (self.send(column)).blank?
    end
  end
  
  # Adjustment Line is a service line with no Service Dates, CPT code, Charges etc. The fields from Payment to PPP will be active.
  # This method identify whether the given EOB contains an adjustment line or not. If it does, returns the id of the service line.
  def adjustment_line_exists?
    self.service_payment_eobs.each do|service_line|
      if !service_line.service_paid_amount.blank? && service_line.service_procedure_charge_amount.blank?
        return service_line.id
      else
        return false
      end
    end
  end

  # Returns the id of an interest service line, if exists. Else returns nil
  # interest service line is the for which:
  # payment = charges = claim interest
  # allow = null
  def interest_service_line_id
    all_service_lines = service_payment_eobs
    # Returns interest service line in self for which the block is true
    unless all_service_lines.blank?
      interest_service_line = all_service_lines.select do
        |service_line| service_line.interest_service_line?
      end
      interest_service_line.first.id if interest_service_line.length > 0
    end
  end

  # Returns the least service from date from
  # saved service lines
  def find_least_date_for_interest_svc_line
    self.reload # to reflect all the newly saved service lines as associated objects
    all_service_lines = service_payment_eobs
    unless all_service_lines.blank?
      # Returns all service lines except interest service line
      non_interest_service_lines = all_service_lines.reject do
        |service_line|  service_line.interest_service_line?
      end
      service_from_dates = non_interest_service_lines.collect do
        |svc_line| svc_line.date_of_service_from
      end
      service_from_dates.compact!
      service_from_dates.sort.first
    end
  end

  # Returns the claim type after computing it
  # the following precendence is taken into account:
  # 1. claim type from 837
  # 2. user entered
  # 3. 'Primary'
  def get_patient_pay_claim_type( claim_type_from_ui, patient_statement_fields_applicable )
    user_chosen_claim_type = nil
    unless claim_type_from_ui.blank? || claim_type_from_ui == '--'
      user_chosen_claim_type = claim_type_from_ui
    end
  
    if !patient_statement_fields_applicable && claim_information && claim_information.claim_type
      claim_information.claim_type_normalized
    elsif user_chosen_claim_type
      user_chosen_claim_type
    else
      'Primary'
    end
  end

  #  For Quadax, if the user captures the ANSI remark code MA07 or MA18 or N89 or N367
  #  in the Standalone ANSI remark code field, the claimtype should set as 19 .

  def check_validity_of_ansi_code(ansi_codes)
    valid_ansi_codes = ['MA07', 'MA18', 'N89']
    valid_codes = false
    ansi_codes.each do |code|
      valid_codes = (valid_ansi_codes.include?(code))
      break if valid_codes == true
    end
    valid_codes
  end

  # Returns the insurance payment eob claim type after applying
  # the claim type computation logic mentioned in:
  #  user_selected_claim_type(Has high priority)
  #  claim_type_code_nineteen_condition
  #  primary_or_secondary_or_tertiary_claim_type_condition
  #  secondary_or_tertiary_claim_type_condition
  #  reversal_claim_type_condition
  #  denial_claim_type_condition
  #  site specific claim type condition
  def get_insurance_eob_claim_type(claim_type_selected, client, facility, remark_codes)
    client_name = client.name
    facility_name = facility.name
    total_ppp = total_primary_payer_amount.to_f
    total_payment = total_amount_paid_for_claim.to_f
    total_charge = total_submitted_charge_for_claim.to_f
    patient_responsibility = total_co_pay.to_f + total_co_insurance.to_f + total_deductible.to_f
    if facility.details[:patient_responsibility]
      patient_responsibility += total_patient_responsibility.to_f
    end
    if !remark_codes.blank?
      remark_codes = remark_codes.flatten.compact
      claim_type_code_nineteen_condition = (((client_name.upcase == 'QUADAX') && (check_validity_of_ansi_code(remark_codes))))
    end

    if(((total_ppp.zero?) && (total_payment > 0) && (total_charge > 0)))
      primary_or_secondary_or_tertiary_claim_type_condition = true
    elsif ((total_ppp.zero?) && (total_payment.zero?) && (total_charge > 0) && (patient_responsibility > 0))    
      if (client_name.upcase.strip == 'ORBOGRAPH' || client_name.upcase.strip == 'ORB TEST FACILITY' || client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER')
        denial_claim_type_condition = true
        primary_or_secondary_or_tertiary_claim_type_condition = false
      else
        primary_or_secondary_or_tertiary_claim_type_condition =  true
      end
    else
      primary_or_secondary_or_tertiary_claim_type_condition = false
    end
    secondary_or_tertiary_condition = ((total_ppp > 0) && (total_payment >= 0) && (total_charge > 0))
    if(secondary_or_tertiary_condition)
      if ((client_name.upcase.strip == 'ORBOGRAPH' || client_name.upcase.strip == 'ORB TEST FACILITY'  || client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER') && total_payment.zero?)
        denial_claim_type_condition = true
        secondary_or_tertiary_claim_type_condition =  false
      else
        secondary_or_tertiary_claim_type_condition = true
      end
    else
      secondary_or_tertiary_claim_type_condition = secondary_or_tertiary_condition
    end
    reversal_claim_type_condition = ((total_ppp <= 0) && (total_payment <= 0) && (total_charge < 0) && (patient_responsibility <= 0))
    denial_claim_type_condition = ((total_ppp.zero?) && (total_payment.zero?) && (total_charge >= 0) && (patient_responsibility.zero?)) unless denial_claim_type_condition == true   
    # assigning processor selected claim_type in the user_selected_claim_type variable
    if claim_type_selected != '--'
      user_selected_claim_type = claim_type_selected
    end

    #assigning processor selected claim_type which is of high priority
    if(secondary_or_tertiary_claim_type_condition)
      # If claim type is obtained from MPI search, assigning that claim type
      if claim_information and !claim_information.claim_type.blank?
        if claim_information.claim_type.to_s == "S"
          'Secondary'
        elsif claim_information.claim_type.to_s == "T"
          'Tertiary'
        else
          'Secondary'
        end
      else
        'Secondary'
      end
    elsif claim_type_code_nineteen_condition
      'Processed as Primary - FAP'
    elsif user_selected_claim_type
      user_selected_claim_type
    elsif(primary_or_secondary_or_tertiary_claim_type_condition)
      # If claim type is obtained from MPI search, assigning that claim type
      if claim_information and !claim_information.claim_type.blank?
        claim_information.claim_type_normalized
      else
        'Primary'
      end
    elsif(reversal_claim_type_condition)
      'Reversal of Prior payment'
    elsif(denial_claim_type_condition)
      if (facility_name.upcase == "PIEDMONT PHYSICIANS GROUP" ||
            facility_name.upcase == "HUDSON" ||
            facility_name.upcase == "PIEDMONT PROF SVC LLC")
        'Primary'
      else
        'Denial'
      end
    else
      if ((client_name.upcase.strip == 'ORBOGRAPH' || client_name.upcase.strip == 'ORB TEST FACILITY'  || client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER') && total_payment.zero?)
        'Denial'
      else
        'Primary'
      end     
    end
  end

  # Provides site specific claim type or claim status code
  # Input :
  # sitecode : sitecode of a facility  . '00S40' = LLU
  # Output :
  # claim type
  def get_customized_claim_type(sitecode)
    copay = total_co_pay.to_f
    co_insurance = total_co_insurance.to_f
    deductable = total_deductible.to_f
    payment = total_amount_paid_for_claim.to_f
    patient_responsibility = copay + co_insurance + deductable
    if !claim_information.blank?
      claim_type_from_837 = claim_information.claim_type.to_s
    end
    if (sitecode == '00S40') && patient_responsibility.zero? && payment.zero?
      '4'
    elsif claim_type_from_837 == 'T' && sitecode == '00895'
      '3'
    elsif !total_primary_payer_amount.to_f.zero?
      '2'
    else
      '1'
    end
  end

  # Calculating processor_input_field_count in eob level
  # by checking constant fields in grid as well as configured fields populated through FCUI.
  def processor_input_field_count(facility, payer = nil)
    payer ||= check_information.payer
    total_field_count_with_data = 0
    claim_level_eob_condition = (category == "claim")
  
    constant_fields = [patient_last_name, patient_first_name, patient_middle_initial,
      patient_suffix, patient_account_number, subscriber_identification_code,
      subscriber_last_name, subscriber_first_name, subscriber_middle_initial,
      subscriber_suffix, provider_organisation, rendering_provider_last_name,
      rendering_provider_first_name, rendering_provider_middle_initial,
      rendering_provider_suffix, provider_npi, provider_tin,
      insurance_policy_number, patient_identification_code,
      patient_identification_code_qualifier, claim_interest, plan_type, claim_type,
      image_page_no, image_page_to_number, rejection_comment]
    fc_ui_fields = [patient_type, carrier_code, hcra, date_received_by_insurer,
      drg_code, claim_number, payer_control_number, marital_status,
      secondary_plan_code, tertiary_plan_code, state_use_only,  fund,
      document_classification, place_of_service, medical_record_number]
    late_filing_charge_field = [late_filing_charge]
  
    if claim_level_eob_condition
      fc_ui_date_fields = [claim_from_date, claim_to_date]
      claim_unique_codes = [copay_reason_code_id, coinsurance_reason_code_id,
        contractual_reason_code_id, deductible_reason_code_id,
        discount_reason_code_id, noncovered_reason_code_id,
        primary_payment_reason_code_id]
      svc_total_amount_fields = [total_non_covered, total_discount, total_co_insurance,
        total_deductible, total_co_pay, total_primary_payer_amount,
        total_contractual_amount]
      svc_total_charge_and_payment_fields = [total_submitted_charge_for_claim,
        total_amount_paid_for_claim]
      fc_ui_claim_unique_codes = [denied_reason_code_id, prepaid_reason_code_id, pr_reason_code_id]
      svc_total_amount_fields_from_fc_ui = [total_denied, total_prepaid,
        total_patient_responsibility]
      expected_payment_field = [total_expected_payment]
    
      configured_date_fields = fc_ui_date_fields.select{|field|
        facility.details[:service_date_from]}
      configured_claim_unique_code = fc_ui_claim_unique_codes.select{|field|
        facility.details[:denied]}
      configured_svc_total_amount_fields = svc_total_amount_fields_from_fc_ui.select{|field|
        facility.details[:denied]}

      total_other_fields = configured_date_fields + claim_unique_codes +
        configured_claim_unique_code + svc_total_charge_and_payment_fields
      
      total_amount_fields = svc_total_amount_fields + configured_svc_total_amount_fields +
        expected_payment_field
      
      total_other_fields_with_data = total_other_fields.select{|field| !field.blank?}
      total_amount_fields_with_data = total_amount_fields.select{|field|
        !field.blank? and field != 0.00}
      
      total_field_count_with_data += total_other_fields_with_data.length +
        total_amount_fields_with_data.length

      total_field_count_with_data += insurance_payment_eobs_reason_codes.length if $IS_PARTNER_BAC
    end
  
    constant_and_configured_field_array = constant_fields.concat(fc_ui_fields)
    constant_and_configured_field_array_with_data = constant_and_configured_field_array.select{|field|
      !field.blank? and field != '--'}
    late_filing_charge_field_with_data = late_filing_charge_field.select{|field|
      !field.blank? and field != 0.00}
    total_field_count_with_data += constant_and_configured_field_array_with_data.length +
      late_filing_charge_field_with_data.length
    total_field_count_with_data += 1 if is_payer_indicator_present?(payer)

    #Adding provider npi and provider tin if its value populated from FCUI
    if provider_npi.blank? and !facility.facility_npi.blank?
      total_field_count_with_data += 1
    end
  
    if provider_tin.blank? and !facility.facility_tin.blank?
      total_field_count_with_data += 1
    end
  
    total_field_count_with_data
  end

  def mpi_applied_status
    mpi_applied_status = ""
    mpi_statistics_data = mpi_statistics_reports.first
    unless mpi_statistics_data.blank?
      if mpi_statistics_data.mpi_status == "MPI Not Used"
        mpi_applied_status = "No"
      else
        mpi_applied_status = "Yes"
      end
    end
    mpi_applied_status
  end

  def eob_image_page_numbers
    eob_image_page_numbers = []
    eob_image_page_numbers << image_page_no
    eob_image_page_numbers.compact.uniq
  end

  def bill_type
    if claim_information
      claim_information.facility_type_code.to_s + claim_information.claim_frequency_type_code.to_s
    end
  end

  def mpi_used?
    mpi_statistics_reports.first.mpi_status.downcase == 'success' if mpi_statistics_reports.first
  end

  def claim_adjustments_elements
    [[total_co_insurance, claim_coinsurance_reasoncode, claim_coinsurance_reasoncode_description, claim_coinsurance_groupcode],
      [total_deductible, claim_deductable_reasoncode, claim_deductable_reasoncode_description, claim_deductuble_groupcode],
      [total_co_pay, claim_copay_reasoncode, claim_copay_reasoncode_description, claim_copay_groupcode],
      [total_non_covered, claim_noncovered_reasoncode, claim_noncovered_reasoncode_description, claim_noncovered_groupcode],
      [total_discount, claim_discount_reasoncode, claim_discount_reasoncode_description, claim_discount_groupcode],
      [total_primary_payer_amount, claim_primary_payment_reasoncode,
        claim_primary_payment_reasoncode_description, claim_primary_payment_groupcode],
      [total_denied, claim_denied_reasoncode, claim_denied_reasoncode_description, claim_denied_groupcode],
      [total_contractual_amount, claim_contractual_reasoncode, claim_contractual_reasoncode_description, claim_contractual_groupcode]]
  end

  def max_date
    service_payment_eobs.collect{|service| service.date_of_service_to}.compact.sort.last
  end

  def min_date
    service_payment_eobs.collect{|service| service.date_of_service_from}.compact.sort.first
  end

  def trace_number(facility, batch)
    if not batch.index_batch_number.blank?
      site_number = facility.sitecode.to_s[-3..-1]
      date = batch.date
      eob_serial_number = serial_number(date, facility.id).to_i.to_s(36).rjust(3, '0')
      date =  date.year.to_s[-1..-1] + date.month.to_s(36) +  date.day.to_s(36)
      batch_sequence_number = batch.index_batch_number.to_i.to_s(36).rjust(2, '0')
      (site_number + date + batch_sequence_number + "0" + eob_serial_number + "0").to_s.upcase
    else
      raise "Index Batch Number missing; cannot compute Trace Number"
    end
  end



  # Computes the index of self object among all the eobs belonging to the
  # same batch date and facility as that of self, ordered by order of creation of eobs
  def serial_number(batch_date, facility_id)
    joins = "inner join check_informations c on c.id = insurance_payment_eobs.check_information_id \
              inner join jobs j on j.id = c.job_id \
              inner join batches b on b.id = j.batch_id \
              inner join facilities f on f.id = b.facility_id"
    ids_of_eobs_with_same_batch_date_and_facility = InsurancePaymentEob.find(:all,
      :joins => joins,
      :select => "insurance_payment_eobs.id",
      :conditions => ["b.date = ? and f.id = ?", batch_date, facility_id])
    ids_of_eobs_with_same_batch_date_and_facility.index(self) + 1
  end

  def claim_payment_xml(xml, claim_payment_count, transaction_index, facility, batch)
    # custom_field_values = get_custom_field_values facility
    custom_field_values = []
    patient_responsibility = sprintf('%.02f',(total_non_covered.to_f + total_deductible.to_f + total_co_pay.to_f))
    xml.claim_payment(:ID => claim_payment_count + 1) do
      xml.tag!(:tran_attrib,  transaction_index + 1)
      xml.tag!(:batch_attrib, 1)
      xml.tag!(:patient_account_no, patient_account_number)
      xml.tag!(:eob_payment, sprintf('%.02f', total_amount_paid_for_claim.to_f))
      xml.tag!(:patient_first_nm, patient_first_name)
      xml.tag!(:patient_middle_nm, patient_middle_initial)
      xml.tag!(:patient_last_nm, patient_last_name)
      xml.tag!(:total_charges, sprintf('%.02f', total_submitted_charge_for_claim.to_f))
      xml.tag!(:member_no_1, subscriber_identification_code)
      xml.tag!(:trace_num, trace_number(facility, batch))
      xml.tag!(:claim_no, claim_number)
      xml.tag!(:patient_name_suffix, patient_suffix)
      xml.tag!(:min_service_dt, claim_from_date || min_date)
      xml.tag!(:max_service_dt, claim_to_date || max_date)
      xml.tag!(:hlsc_claim_no, claim_payment_count + 1)
      xml.tag!(:claim_guid, guid)
      xml.tag!(:patient_responsibility_am, patient_responsibility)
      xml.tag!(:mpi_loaded_in, mpi_used? ? 1: 0)
      xml.tag!(:balancing_record_in, (balance_record_type.nil? ? 0 : 1) )
      xml.tag!(:bill_type_cd, bill_type)
      xml.tag!(:provider_plan_cd)
      xml.tag!(:output_file_nm, (output_file.file_name.to_s.upcase if !output_file.blank?))
      xml.tag!(:transmit_dt, (output_file.start_time.strftime("%Y-%m-%d")if !output_file.blank?))
      xml.tag!(:user1, (custom_field_values[:field1] if (!custom_field_values.blank? && custom_field_values.has_key?("field1"))))
      xml.tag!(:user2, (custom_field_values[:field2] if (!custom_field_values.blank? && custom_field_values.has_key?("field2"))))
      xml.tag!(:user3, (custom_field_values[:field3] if (!custom_field_values.blank? && custom_field_values.has_key?("field3"))))
      xml.tag!(:user4, (custom_field_values[:field4] if (!custom_field_values.blank? && custom_field_values.has_key?("field4"))))
      xml.tag!(:user5, (custom_field_values[:field5] if (!custom_field_values.blank? && custom_field_values.has_key?("field5"))))
    end
    claim_payment_count += 1
  end

  def doc_xml(xml, doc_count, claim_payment_count)
    check_information.job.images_for_jobs.each_with_index do |img, i|
      if eob_image_page_numbers.include?(i + 1)
        xml.doc(:ID => doc_count + 1) do
          xml.tag!(:claim_payment_attrib, claim_payment_count + 1)
          xml.tag!(:filename, img.filename)
        end
        doc_count += 1
      end
    end
    hr_eob_output_files = OutputActivityLog.all(:conditions => ["file_format = ? \
                          and eobs_output_activity_logs.insurance_payment_eob_id = ?",
        'HREOB', self.id],
      :include => :eobs_output_activity_logs)
    hr_eob_output_files.each do |hreob|
      xml.doc(:ID => doc_count + 1) do
        xml.tag!(:claim_payment_attrib, claim_payment_count + 1)
        xml.tag!(:filename, hreob.file_name)
      end
      doc_count += 1
    end
    claim_payment_count += 1
    return doc_count, claim_payment_count
  end

  def claim_adjustment_xml(xml, claim_payment_count, facility, payer, claim_adjustment_count)
    codes_and_descriptions_to_notify = []
    rc_ids_to_reset_notify = []
    client = facility.client
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, self, client, facility)
    associated_codes_for_adjustment_elements = adjustment_reason_elements
    associated_codes_for_adjustment_elements.each do |adjustment_reason|
      amount = amount("#{adjustment_reason}_amount")
      crosswalked_codes = reason_code_crosswalk.get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
      mapped_reason_code, reason_code = crosswalked_codes[:reason_code], crosswalked_codes[:reason_code]
      mapped_reason_code_description = crosswalked_codes[:reason_code_description]
      all_reason_codes = crosswalked_codes[:all_reason_codes]
      if reason_code.blank?
        if !all_reason_codes.blank? && !all_reason_codes[0].blank?
          reason_code = all_reason_codes[0][0]
        end
      end
      group_code = crosswalked_codes[:group_code]
      client_code = crosswalked_codes[:client_code]
      mapped_code = crosswalked_codes[:cas_02]
      reason_code = mapped_code if reason_code.blank?
      service_quantity = (service_quantity.blank? ? 0 : service_quantity)
      if !amount.to_f.zero? && !reason_code.blank? && !group_code.blank?
        xml.claim_payment_adjustment(:ID => claim_adjustment_count + 1) do
          xml.tag!(:claim_payment_attrib, claim_payment_count + 1)
          xml.tag!(:claim_adjustment_group_cd, group_code)
          xml.tag!(:claim_adjustment_reason_cd, mapped_code)
          xml.tag!(:adjustment_am, sprintf('%.02f', amount.to_f))
          xml.tag!(:adjustment_qt, (service_quantity || 0))
          xml.tag!(:payer_reason_cd, reason_code)
          xml.tag!(:client_system_cd, client_code)
          xml.tag!(:reporting_activity_1_tx, (crosswalked_codes[:reporting_activity1]))
          xml.tag!(:reporting_activity_2_tx, (crosswalked_codes[:reporting_activity2]))
        end
        claim_adjustment_count += 1
      end
      if !all_reason_codes.blank?
        all_reason_codes.each do |rc_record_array|
          if !rc_record_array.blank?
            code = rc_record_array[0]
            description = rc_record_array[1]
            notify = rc_record_array[2]
          end
          if notify == true || (code != mapped_reason_code || description != mapped_reason_code_description)
            if !code.blank? && !description.blank?
              codes_and_descriptions_to_notify << [code, description, claim_payment_count + 1]
            end
          end
        end
      end
      reason_code_objects = reason_code_crosswalk.get_reason_code_records_for_adjustment_reason(adjustment_reason)
      reason_code_objects.each do |rc_obj|
        if rc_obj.notify == true
          rc_ids_to_reset_notify << rc_obj.id
        end
      end
    end
    if !rc_ids_to_reset_notify.blank?
      ReasonCode.reset_notify(rc_ids_to_reset_notify.flatten.compact.uniq)
    end
    claim_payment_count += 1
    return claim_payment_count, claim_adjustment_count, codes_and_descriptions_to_notify
  end

  def output_file
    batch_id = check_information.job.batch.id
    output_file = output_activity_logs.find_by_file_format('835_source') if !output_activity_logs.blank?
    if output_file.blank?
      output_file = OutputActivityLog.find_by_file_format_and_batch_id('835_source', batch_id)
    end
    output_file
  end

  # Returns whether the payment amount is zero or not
  def zero_payment?
    total_amount_paid_for_claim.to_f.zero?
  end

  # Provides all the codes that determines by type in an array.
  # To be used specifically for Client F output.
  #
  # Input :
  # facility : Facility object of the claim in process.
  # payer : Payer object of the claim in process.
  # type : The configuration to retrieve the type of code,
  #   Eg : Reason Code, Reason Code Description.
  #
  # Output :
  # An array of codes that determines by the type.
  def reason_codes_for_service_line(facility, payer)
    reason_codes = []
    client = facility.client
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, self, client, facility)
    associated_codes_for_adjustment_elements = adjustment_reason_elements
    associated_codes_for_adjustment_elements.each do |adjustment_reason|
      crosswalked_codes = reason_code_crosswalk.get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
      if !crosswalked_codes[:all_reason_codes].blank?
        crosswalked_codes[:all_reason_codes].each do |rc_and_desc|
          if !rc_and_desc.blank?
            reason_codes << rc_and_desc[0]
          end
        end
      end
    end
    reason_codes = reason_codes.flatten.compact.uniq
    reason_codes if !reason_codes.blank?
  end

  # Provides the claim_status_code for a particular eob(BAC).
  # Input :
  # client, facility
  # Output : computed claim_status_code
  def claim_status_code(client, facility)
    payer = check_information.payer
    sitecode = facility.sitecode.to_s.upcase
    sitecodes_for_custiomized_claim_type = ['00895', '00985', '00986',
      '00987', '00988', '00989', '00K22', '00K23', '00K39', '00S40']
    if sitecodes_for_custiomized_claim_type.include?(sitecode)
      claim_status_code = get_customized_claim_type(sitecode)
    else
      if service_payment_eobs.blank?
        entity = self
      else
        entity = service_payment_eobs[0].find_service_line_having_reason_codes( service_payment_eobs)
      end
      if entity
        crosswalked_codes = find_reason_code_crosswalk_of_last_adjustment_reason(client, facility, payer)
    
        claim_status_code = compute_claim_status_code(facility, crosswalked_codes)
      else
        claim_status_code = '1'
      end
    end
    claim_status_code
  end

  # Assigns weights to each 'claim_type'
  # based on value to be printed in 835
  def claim_type_weight
    case claim_type
    when 'Primary', 'P'
      1
    when 'Secondary', 'S'
      2
    when 'Tertiary', 'T'
      3
    when 'Denial', 'D'
      4
    when 'Processed as Primary - FAP'
      19
    when 'Processed as Secondary, forwarded to Additional Payer(s)'
      20
    when 'Processed as Tertiary, forwarded to Additional Payer(s)'
      21
    when 'Reversal of Prior payment', 'R'
      22
    when  'Not our Claim, forwarded to Additional Payer(s)'
      23
    when 'Predetermination Pricing Only - No Payment'
      25
    end
  end

  # Provides the claim_status_code based on requirements
  #
  # Input :
  # type : the crosswalk or associated record for the reason code
  # type : the selection of the mapped code for the code type(HIPAA)
  #
  # Output :
  # Returns the claim_status_code based on the requirements
  def compute_claim_status_code(facility, crosswalked_codes)
    total_payment = total_amount_paid_for_claim.to_f
    total_charge = total_submitted_charge_for_claim.to_f
    total_coins =  total_co_insurance.to_f
    total_ppp =    total_primary_payer_amount.to_f
    total_deduct = total_deductible.to_f
    if crosswalked_codes
      denied_claim_status_code = crosswalked_codes[:denied_claim_status_code]
      claim_status_code = crosswalked_codes[:claim_status_code]
    end
    default_site_level_claim_status = facility.details[:site_level_claim_status]
    if default_site_level_claim_status.blank?
      default_site_level_claim_status = 1
    end
    if (total_charge + total_payment).to_f < 0.0
      status_code = 22
    elsif (total_coins + total_deduct + total_payment).to_f.zero?
      status_code = 4
    elsif not total_ppp.to_f.zero?
      status_code = 2
    elsif !crosswalked_codes.blank? && crosswalked_codes[:hipaa_code].blank?
      status_code = default_site_level_claim_status
    elsif (!crosswalked_codes.blank? && !crosswalked_codes[:hipaa_code].blank?) && zero_payment?
      status_code = denied_claim_status_code || claim_status_code || default_site_level_claim_status
    elsif (!crosswalked_codes.blank? && !crosswalked_codes[:hipaa_code].blank? && !zero_payment?)
      status_code = claim_status_code || default_site_level_claim_status
    elsif crosswalked_codes.blank?
      status_code = default_site_level_claim_status
    else
      status_code = 1
    end
    status_code.to_s
  end

  # Provides mapped_code and reason_code_id
  #
  # Input :
  # type : the eob for claim level and service line for service level eobs having reason codes
  # type : the facility and payer
  #
  # Output :
  # Returns the mapped_code and reason_code id
  def find_reason_code_crosswalk_of_last_adjustment_reason(client, facility, payer)
    associated_codes_for_adjustment_elements = adjustment_reason_elements.reverse
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, self, client, facility)
    associated_codes_for_adjustment_elements.each do |adjustment_reason|
      amount = amount("#{adjustment_reason}_amount")
      unless amount.to_f.zero?
        crosswalked_codes = reason_code_crosswalk.get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
        return crosswalked_codes
      end
    end
    return nil
  end

  def patient_name(lnamefirst = false)
    patient_name = []
    patient_name << (patient_first_name.present? ? patient_first_name : nil)
    patient_name << (patient_middle_initial.present? ? patient_middle_initial : nil)
    patient_name << (patient_last_name.present? ? patient_last_name : nil)
    patient_name << (patient_suffix.present? ? patient_suffix : nil)
    if lnamefirst
      patient_name[0], patient_name[1],patient_name[2] = patient_name[2], patient_name[0],patient_name[1]
    end
    patient_name = patient_name.compact.join(' ')
    patient_name = patient_name.upcase
  end

  def is_payer_indicator_present?(payer)
    if payer
      payid= payer.supply_payid
      unless payid.blank?
        payid_array = ["CMUN1", "60054", "23222"]
        condition_for_user_input_in_payer_indicator = payid_array.include?(payid)
        if condition_for_user_input_in_payer_indicator
          payer_indicator_field = [payer_indicator]
        end
      end
    end
    payer_indicator_field.blank? ? false : true
  end

  def image_file_name
    image_types.first.images_for_job.filename rescue nil
  end

  def primary_codes
    codes = ["coinsurance_reason_code", "contractual_reason_code", "denied_reason_code", "discount_reason_code", "deductible_reason_code", "primary_payment_reason_code", "noncovered_reason_code", "copay_reason_code"]
    codes.map{|c| self.send(c)}.compact.map{|j| j.reason_code}.join(";")
  end
  
  def secondary_codes
    reason_codes.collect(&:reason_code).join(";")
  end
  
  def proprietary_codes
    primary = primary_codes
    secondary = secondary_codes
    if primary.present? && secondary.present?
      primary + ";" + secondary
    else
      primary + secondary
    end
  end

  # +----------------------------------------------------------------------------+
  # This method is for getting and setting of primary and secondary              |
  #  reason_code_ids and uniquecodes for QA view.                                |
  # Input  : one eob record                                                      |
  # Output : A string of reason_code_ids , separated by semicolon(;) is set to   |
  # respective amount_type ids. Eg: noncovered_id = "12;23;34".                  |
  # Implementation: For each eob, we are setting reason_code_ids and unique codes|
  # Step1: Define attr_accesors for Reason Code ids and Unique Codes. This is for|
  #        showing the the unique codes and setting hidden fields in QA view.    |
  # Step2: Create a hash of primary_reason_code_ids with key as type of amount & |
  #        value as reason code id from table insurance_payment_eobs.            |
  # Step3: Inject this primary_reason_code_id into respective amount_type arrays.|
  # Step4: If Partner is BAC, then retrieve Secondary_reason_code_ids from       |
  #        table insurance_payment_eobs_reason_codes and push into respective    |
  #        arrays.                                                               |
  # Step5: Get unique codes corresponding to the reason code ids by using        |
  #        'get_unique_codes_for()' and assign to attr_accessors.                |
  #        This method 'get_unique_codes_for()' will return a string of Unique   |
  #        Codes seperated by ';'.                                               |
  # Step6: Get a string of Reason Code ids separated by ';' by using the method  |
  #        "get_reason_code_ids_seperated_by_semicolon". And assign to respective|
  #        attr_accessors.                                                       |
  # +----------------------------------------------------------------------------+
  def self.set_unique_codes_and_reason_code_ids_for_claim(eobs, is_multiple_reason_codes_applicable, attribute_to_set = nil)
    eobs.each do |eob|
      eob = set_adjustment_codes_and_reason_code_ids(eob, is_multiple_reason_codes_applicable, attribute_to_set) if is_adjustment_code_associated?(eob)
    end
    eobs
  end

  def self.set_crosswalked_codes(payer, eobs, client, facility)
    eobs.each do |eob|
      if eob.category == 'claim'
        eob = set_crosswalked_codes_for_object(payer, eob, client, facility)
      end
    end
    eobs
  end

  def get_custom_field_values facility
    client = facility.client
    all_custom_fields = {:field1 => nil, :field2 => nil, :field3 => nil, :field4 => nil, :field5 => nil}
    custom_fields = client.custom_fields
    if custom_fields.class == Hash
      client.custom_fields.merge!(all_custom_fields){ |key, v1, v2| eval("#{v1}") if v1 }
    end
  end

  #This is for getting all primary reason code ids associated to an eob.
  def get_primary_reason_code_ids_of_eob
    reason_code_ids = []
    reason_code_ids << noncovered_reason_code_id unless noncovered_reason_code_id.blank?
    reason_code_ids << denied_reason_code_id unless denied_reason_code_id.blank?
    reason_code_ids << discount_reason_code_id unless discount_reason_code_id.blank?
    reason_code_ids << coinsurance_reason_code_id unless coinsurance_reason_code_id.blank?
    reason_code_ids << deductible_reason_code_id unless deductible_reason_code_id.blank?
    reason_code_ids << copay_reason_code_id unless copay_reason_code_id.blank?
    reason_code_ids << primary_payment_reason_code_id unless primary_payment_reason_code_id.blank?
    reason_code_ids << prepaid_reason_code_id unless prepaid_reason_code_id.blank?
    reason_code_ids << pr_reason_code_id unless pr_reason_code_id.blank?
    reason_code_ids << contractual_reason_code_id unless contractual_reason_code_id.blank?
    reason_code_ids << miscellaneous_one_reason_code_id unless miscellaneous_one_reason_code_id.blank?
    reason_code_ids << miscellaneous_two_reason_code_id unless miscellaneous_two_reason_code_id.blank?
    reason_code_ids
  end

  # +--------------------------------------------------------------------------+
  # This method is for validating patient first, last and middle initial names.|
  # -- Patient first name and last name - For BAC Required alphabets, numeric,hyphen   |
  #    or period only. Otherwise error message will throw.
  # -- Patient first name and last name - For NBAC Required alphabets, numeric,hyphen,   |
  #    space or period only if patient_name_format_validation is checked in FCUI.
  #    Otherwise error message will throw.                     |
  # -- Patient middle initial - Required alphabets only. Otherwise error       |
  #    message will throw.                                                     |
  # +--------------------------------------------------------------------------+
  def validate_patient_name(facility)
    error_message = ""
    error_message += "Patient Name - First/Last should be Alphanumeric, hyphen or period only!" if $IS_PARTNER_BAC &&
      !patient_last_name.blank? && !patient_first_name.blank? &&
      (patient_last_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !patient_last_name.match(/^[A-Za-z0-9\-\.]*$/)) &&
      (patient_first_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !patient_first_name.match(/^[A-Za-z0-9\-\.]*$/))

    error_message += "Patient Name - First/Last should be Alphanumeric, hyphen, space or period only!" if !$IS_PARTNER_BAC &&
      facility.details[:patient_name_format_validation] &&
      !patient_last_name.blank? && !patient_first_name.blank? &&
      (patient_last_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !patient_last_name.match(/^[A-Za-z0-9\-\s\.]*$/)) &&
      (patient_first_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !patient_first_name.match(/^[A-Za-z0-9\-\s\.]*$/))
    error_message += " Patient Name - Middle Initial should be letters only!" if !patient_middle_initial.blank? && !patient_middle_initial.match(/^[A-Za-z]*$/)
    error_message unless error_message == ""
  end
  
  # +--------------------------------------------------------------------------+
  # This method is for validating patient account number.                      |
  # -- Patient account number - Required alphabets, numeric,  hyphen  and      |
  #    period only for BAC. Otherwise error message will throw.                |
  # -- Patient account number - Required alphabets, numeric,  hyphen, period,  |
  #    and forward slah only for non BAC. Otherwise error message will throw.  |
  # -- No consecutive occurrence of special characters allowed                 |
  # -- No maximum limit to any special characters except forward slash(3)      |
  # +--------------------------------------------------------------------------+
  def validate_patient_account_number
    error_message = ""
    error_message += "Patient Account Number should be Alphanumeric, hyphen or period only!" if $IS_PARTNER_BAC &&
      !patient_account_number.blank? &&
      (patient_account_number.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !patient_account_number.match(/^[A-Za-z0-9\-\.]*$/))
    error_message += "Patient Account Number should be Alphanumeric, hyphen, period or forward slash only!" if !$IS_PARTNER_BAC &&
      !patient_account_number.blank? &&
      (patient_account_number.match(/\.{2}|\-{2}|\/{2}|^[\-\.\/]+$/) ||
        !patient_account_number.match(/^[A-Za-z0-9\-\.\/]*$/) ||
        (patient_account_number.gsub(/[a-zA-Z0-9\.\-]/, '').match(/\/{4,}/)))
    errors.add(:base, error_message) unless error_message == ""
  end

  def get_reason_code_ids_of_eob_and_svc_of_a_job
    reason_code_ids_of_eob_and_svc = []

    reason_code_ids = get_primary_reason_code_ids_of_eob
    reason_code_ids_of_eob_and_svc += reason_code_ids unless reason_code_ids.blank? #primary

    reason_codes_associated_to_eobs = reason_codes
    unless reason_codes_associated_to_eobs.blank?
      reason_codes_associated_to_eobs.each do |rc|
        reason_code_ids_of_eob_and_svc << rc.id#secondary
      end
    end

    unless category == "claim"
      services = service_payment_eobs
      unless services.blank?
        services.each do |service_line|
          reason_code_ids = service_line.get_primary_reason_code_ids_of_svc
          reason_code_ids_of_eob_and_svc += reason_code_ids unless reason_code_ids.blank? #primary
          reason_codes_associated_with_service = service_line.reason_codes

          unless reason_codes_associated_with_service.blank?
            reason_codes_associated_with_service.each do |rc|
              reason_code_ids_of_eob_and_svc << rc.id #secondary
            end
          end
        end
      end
    end
    reason_code_ids_of_eob_and_svc.uniq
  end

  def output_claim_type_weight client, facility, facility_config
    required_claim_types = facility_config.required_claim_types.to_s.strip.split(',')
    actual_claim_type_weight = claim_status_code(client, facility)
    if required_claim_types.blank?
      actual_claim_type_weight
    else
      (required_claim_types.include?actual_claim_type_weight.to_s) ? actual_claim_type_weight : 1
    end
  end
  
  # Returns the least service from date from
  # eob service lines
  def least_date_for_eob_svc_line
    least_service_from_date = self.service_payment_eobs.minimum(:date_of_service_from)
  end

  def old_eob_of_goodman?
    cut_of_date = Date.new(2000,1,1)
    service_payment_eobs.any?{|service| (cut_of_date <=> service.date_of_service_from) == 1 }
  end

  def provider_adjustment_amount
    prov_adj = check_information.job.get_all_provider_adjustments.select(:amount).where(:image_page_number => image_page_no).first
    (prov_adj ? prov_adj.amount.to_f : 0.0)
  end

  def claim_level_supplemental_amount
    amount = nil
    if check_information.eob_type == 'Patient'
      unless total_amount_paid_for_claim.blank? || total_amount_paid_for_claim.to_f.zero?
        amount = amount('total_amount_paid_for_claim')
      end
    else
      unless total_allowable.blank? || total_allowable.to_f.zero?
        amount = amount('total_allowable')
      end
    end
    amount
  end

  def normalised_eob(fac_name)
    normalised_eob = Facility.find_by_name(fac_name).details["claim_normalized_factor"]
    if normalised_eob.nil? || normalised_eob == ""
      return 0
    else
      return normalised_eob
    end
  end

  def normalised_svc(fac_name)
    normalised_svc = Facility.find_by_name(fac_name).details["service_line_normalised_factor"]
    if normalised_svc.nil? || normalised_svc == ""
      return 0
    else
      return normalised_svc
    end
  end

  def get_remark_codes
    ansi_remark_codes.map(&:adjustment_code)
  end

  def get_formatted_tooth_number
    tooth_number_array = self.service_payment_eobs.map{|svc| svc.tooth_number}.compact
    tooth_number_formatted = tooth_number_array.to_s.gsub(/\,/,":").gsub(/\"/,"").chomp("]").delete("[")
    tooth_number_formatted
  end

  def is_orphan_adjustment_code?(facility, adjustment_reason)
    facility.details[:cas_segment_for_orphan_adjustment_code] &&
      self.send("#{adjustment_reason}_amount").blank? &&
      (self.send("#{adjustment_reason}_reason_code_id").present? ||
        self.send("#{adjustment_reason}_hipaa_code_id").present?)
  end

end
