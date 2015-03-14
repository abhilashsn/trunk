require 'OCR_Data'
require 'adjustment_reason'

include ApplicationHelper

class ServicePaymentEob < ActiveRecord::Base
  include DcGrid
  include AdjustmentReason
  include OCR_Data
  extend ReasonCodesHelper::ClassMethods
  
  attr_accessor :style,:coordinates, :page, :service_balance
  attr_accessor :coinsurance_adjustment_codes, :contractual_adjustment_codes,
    :copay_adjustment_codes, :deductible_adjustment_codes, :denied_adjustment_codes,
    :discount_adjustment_codes, :noncovered_adjustment_codes, :primary_payment_adjustment_codes,
    :prepaid_adjustment_codes, :pr_adjustment_codes,
    :miscellaneous_one_adjustment_codes, :miscellaneous_two_adjustment_codes
  attr_accessor :coinsurance_id, :contractual_id, :copay_id, :deductible_id,
    :denied_id, :discount_id, :noncovered_id, :prepaid_id, :patient_responsibility_id,
    :primary_payment_id, :miscellaneous_one_id, :miscellaneous_two_id
  attr_accessor :coinsurance_crosswalked_codes, :contractual_crosswalked_codes,
    :copay_crosswalked_codes, :deductible_crosswalked_codes, :denied_crosswalked_codes,
    :discount_crosswalked_codes, :noncovered_crosswalked_codes, :primary_payment_crosswalked_codes,
    :prepaid_crosswalked_codes, :pr_crosswalked_codes,
    :miscellaneous_one_crosswalked_codes, :miscellaneous_two_crosswalked_codes
  belongs_to :insurance_payment_eob
  belongs_to :claim_service_information
  has_many :service_payment_eobs_ansi_remark_codes, :dependent => :destroy
  has_many :ansi_remark_codes, :through => :service_payment_eobs_ansi_remark_codes
  has_many :service_payment_eobs_reason_codes, :dependent => :destroy
  has_many :reason_codes, :through => :service_payment_eobs_reason_codes

  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details"
  has_details  :date_of_service_from,
    :date_of_service_to,
    :service_procedure_code,
    :service_quantity,
    :service_procedure_charge_amount,
    :service_allowable,
    :service_co_pay,
    :contractual_amount,
    :service_deductible,
    :service_co_insurance,
    :service_paid_amount,
    :service_discount,
    :revenue_code,
    :service_modifier1,
    :primary_payment,
    :service_no_covered,
    :service_modifier2,
    :service_modifier3,
    :service_modifier4,
    :service_provider_control_number,
    :rx_number,
    :expected_payment,
    :denied
  
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

  alias_attribute :submitted_charge_amount, :service_procedure_charge_amount
  alias_attribute :paid_amount, :service_paid_amount
  alias_attribute :coinsurance_amount, :service_co_insurance
  alias_attribute :copay_amount, :service_co_pay
  alias_attribute :deductible_amount, :service_deductible
  alias_attribute :denied_amount, :denied
  alias_attribute :discount_amount, :service_discount
  alias_attribute :noncovered_amount, :service_no_covered
  alias_attribute :primary_payment_amount, :primary_payment
  alias_attribute :prepaid_amount, :service_prepaid
  alias_attribute :patient_responsibility_amount, :patient_responsibility
  alias_attribute :miscellaneous_one_amount, :miscellaneous_one_adjustment_amount
  alias_attribute :miscellaneous_two_amount, :miscellaneous_two_adjustment_amount

  after_update :create_qa_edit

  before_save do |obj|
    obj.upcase_grid_data(['details'])
  end
  
  def create_qa_edit
    QaEdit.create_records(self)
  end
 
  scope :secondary_reason_codes_by_adjustment_reason, lambda { |id, adjustment_reason|
    { :select => ["service_payment_eobs_reason_codes.* "],
      :joins => [:service_payment_eobs_reason_codes],
      :conditions => ['service_payment_eobs_reason_codes.service_payment_eob_id = ? AND service_payment_eobs_reason_codes.adjustment_reason = ?',
        id, adjustment_reason]}
  }

  # Unused Method
  def self.in_payment_codes(id)
    @payment_codes_inpatient = ServicePaymentEob.find(id).inpatient_code
    if (!@payment_codes_inpatient.blank?)
      @inpatient_code = @payment_codes_inpatient.split(',')
      return @inpatient_code
    end
  end

  # Unused Method
  def self.out_payment_codes(id)
    @payment_codes_outpatient = ServicePaymentEob.find(id).outpatient_code
    if (!@payment_codes_outpatient.blank?)
      @outpatient_code = @payment_codes_outpatient.split(',')
      return @outpatient_code
    end
  end

  def get_tooth_number 
    self.tooth_number
  end
  
  def self.sum_attribute(attr, eob_id)
    self.sum(attr.to_sym,  :conditions=>["insurance_payment_eob_id = ?", eob_id])
  end
  
  # +----------------------------------------------------------------------------+
  # This method will return service_payment_eob records associated to an         |
  # insurance_payment_eob for QA view.                                                       |
  # Input  : insurance_payment_eob_id.                                           |
  # Output : service_lines(ie. Service_payment_eobs)                             |
  # Implementation: For each eob, we are setting reason_code_ids and unique codes|
  # Step1: Define attr_accesors for Reason Code ids and Unique Codes. This is for|
  #        showing the the unique codes and setting hidden fields in QA view.    |
  # Step2: Retreive all service_payment_eobs associated to insurance_payment_eob.|
  # Step3: Create a hash of primary_reason_code_ids with key as type of amount & |
  #        value as reason code id from table service_payment_eobs.              |
  # Step4: Inject this primary_reason_code_id into respective amount_type arrays.|
  # Step5: If Partner is BAC, then retrieve Secondary_reason_code_ids from       |
  #        table service_payment_eobs_reason_codes and push into respective      |
  #        arrays.                                                               |
  # Step6: Get unique codes corresponding to the reason code ids by using        |
  #        'get_unique_codes_for()' and assign to attr_accessors.                |
  #        This method 'get_unique_codes_for()' will return a string of Unique   |
  #        Codes seperated by ';'.               |                               |
  # Step7: Get a string of Reason Code ids seperated by ';' by using the method  |
  #        "get_reason_code_ids_seperated_by_semicolon". And assign to respective|
  #        attr_accessors.                                                       |
  # Step8: Return Service lines.                                                 |
  # +----------------------------------------------------------------------------+
  def self.service_line(claim_id, is_multiple_reason_codes_applicable, attribute_to_set = nil)
    service_lines = self.find(:all,:conditions => ["insurance_payment_eob_id = ?", claim_id], :include=> [:insurance_payment_eob, :service_payment_eobs_reason_codes, {:ansi_remark_codes => :service_payment_eobs_ansi_remark_codes}])
    unless service_lines.blank?
      service_lines.each do |service_line|
        service_line = set_adjustment_codes_and_reason_code_ids(service_line, is_multiple_reason_codes_applicable, attribute_to_set) if is_adjustment_code_associated?(service_line)
      end
    end
    service_lines
  end

  def self.set_crosswalked_codes(claim_id, payer, client, facility)
    service_lines = self.find(:all,:conditions => ["insurance_payment_eob_id = ?", claim_id], :include=> [:insurance_payment_eob, :service_payment_eobs_reason_codes, {:ansi_remark_codes => :service_payment_eobs_ansi_remark_codes}])
    service_lines.each do |service_line|
      service_line = set_crosswalked_codes_for_object(payer, service_line, client, facility)
    end
    service_lines
  end
  
  # Returns if the current service line object satisfies the criteria for interest service line, i.e.
  # charge = payment = claim interest and
  # allow is nil
  # This is called where based on this value, allowable field is decided to be mandatory or not.
  def interest_service_line?(previous_interest_amount = nil)
    charge = service_procedure_charge_amount
    if !previous_interest_amount.to_f.zero?
      interest_amount = previous_interest_amount
    elsif !insurance_payment_eob.blank?
      interest_amount = insurance_payment_eob.claim_interest
    end
    if !interest_amount.to_f.zero?
      charge_eql_interest = charge == interest_amount
      charge_eql_payment = charge == service_paid_amount
      charge_eql_interest && charge_eql_payment && service_allowable.to_f.zero?
    else
      false
    end    
  end
  
  #  Returns a hash with keys that are attributes of a service line,
  #  values as below:
  #  payment = charges = claim interest
  #  allow = null
  #  service dates = least of service dates of other serviceline of the claim
  #  if checkbox named 'service_date_from' is checked in FC UI.
  #  Otherwise service date will be bank_deposit_date
  #  This kind of service line is an Interest Service Line
  # Input : batch, facility
  # Output : A hash containing charge, payment and date values
  def prepare_interest_svc_line(batch, facility)
    interest = insurance_payment_eob.claim_interest.to_f
    charge = service_procedure_charge_amount.to_f

    if facility.details[:service_date_from]
      min_date = insurance_payment_eob.find_least_date_for_interest_svc_line
    end
    min_date ||= batch.bank_deposit_date
    insurance_payment_eob.total_submitted_charge_for_claim =
      ( insurance_payment_eob.total_submitted_charge_for_claim - charge )+ interest
    insurance_payment_eob.total_amount_paid_for_claim =
      ( insurance_payment_eob.total_amount_paid_for_claim - charge ) + interest
    insurance_payment_eob.save
    
    { :service_procedure_charge_amount => interest,
      :service_paid_amount => interest,
      :date_of_service_from => min_date, :date_of_service_to => min_date }
  end


  # This provides the balance amount of a service linee
  # Output : Balance amount with 2 decimal places
  def service_balance
    adjustment_amounts = [ coinsurance_amount, copay_amount, deductible_amount, denied_amount,
      discount_amount, noncovered_amount, primary_payment_amount, prepaid_amount,
      patient_responsibility_amount, contractual_amount, miscellaneous_one_adjustment_amount,
      miscellaneous_two_adjustment_amount, miscellaneous_balance ]

    total_adjustment_amount = adjustment_amounts.inject(0) {|sum, value| sum + value.to_f }
    balance_amount = service_procedure_charge_amount.to_f - (service_paid_amount.to_f + total_adjustment_amount)
    balance_amount = balance_amount.round(2)
    sprintf("%.2f", balance_amount)
  end
  
  #returns the group code if valid, else returns nil
  def group_code(group_code)
    unless (self.send(group_code).blank? || self.send(group_code).strip == "..")
      self.send(group_code).to_s.strip
    else
      nil
    end
  end
  
  #returns the amount if exists, else returns 0
  def amount(col_name)
    amount = send(col_name).to_f unless (send(col_name).blank? || send(col_name) == 0.00)
    if amount
      amount = ((amount == amount.truncate) ? amount.truncate : amount)
      amount
    else
      0
    end
  end
  
  #This will return the stle for an OCR data, depending on its origin
  #4 types of origins are :
  #0 = imported from 837
  #1= read by OCR with 100% confidence (questionables_count =0)
  #2= read by OCR with < 100% confidence (questionables_count >0)
  #3= blank data
  #column  is the name of the database column of which you want to get the style
  def style_for(column,present)
    if(present == true)
      class_value = "imported"
    else
      method_to_call = "#{column}_data_origin"
      begin
        case self.details[method_to_call.to_sym]
        when Origins::IMPORTED
          class_value =  "ocr_data imported"
        when Origins::CERTAIN
          class_value = "ocr_data certain"
        when Origins::UNCERTAIN
          class_value = "ocr_data uncertain"
        when Origins::BLANK
          class_value = "ocr_data blank"
        else
          class_value = "ocr_data blank"
        end
      rescue NoMethodError
        # Nothing matched, assign default
        Origins::BLANK
      end
    end
    class_value 
  end

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
   
  # Adjustment Line is a service line with no Service Dates, CPT code, Charges etc. The fields from Payment to PPP will be active.
  # This method identify whether the given service line is an adjustment line or not.
  def adjustment_line_is?
    adjustment_amounts = [coinsurance_amount, copay_amount, deductible_amount,
      denied_amount, discount_amount, noncovered_amount, primary_payment_amount,
      prepaid_amount, patient_responsibility_amount, contractual_amount,
      miscellaneous_one_adjustment_amount, miscellaneous_two_adjustment_amount,
      miscellaneous_balance]

    total_adjustment_amount = adjustment_amounts.inject(0) {|sum, value| sum + value.to_f }
    balance_amount = service_procedure_charge_amount.to_f - (service_paid_amount.to_f + total_adjustment_amount)

    non_zero_adjustment_amounts = adjustment_amounts.keep_if {|v| !v.to_f.zero?}
    is_there_atleast_one_adjustment_amount = non_zero_adjustment_amounts.length > 0

    balance_amount.to_f.round(2).zero? && service_procedure_charge_amount.blank? && service_allowable.blank? &&
      is_there_atleast_one_adjustment_amount
  end
  
  # Gets reason codes for patient Responsibility amounts
  def pr_reason_codes
    reason_codes = []
    reason_codes << (coinsurance_code unless service_co_insurance.to_f.zero?)
    reason_codes << (deductuble_code unless service_deductible.to_f.zero?)
    reason_codes << (copay_code unless service_co_pay.to_f.zero?)
    reason_codes = reason_codes.compact
    reason_codes
  end
  
  # Returns an array of CAS codes for patient Responsibility amounts
  # If amount is non zero, fetch HIPAA Code, if exists
  # else assume RC itself is HIPAA code
  def pr_cas_codes
    cas_codes = []
    cas_codes << ((hipaa_code('coinsurance_code') || coinsurance_code) unless service_co_insurance.to_f.zero?)
    cas_codes << ((hipaa_code('deductuble_code') || deductuble_code) unless service_deductible.to_f.zero?)
    cas_codes << ((hipaa_code('copay_code') || copay_code) unless service_co_pay.to_f.zero?)
    cas_codes = cas_codes.compact
    cas_codes
  end
  
  # Gets all reason codes for which the amount exists
  def get_all_reason_codes
    reason_codes = []
    reason_codes << (coinsurance_code unless service_co_insurance.to_f.zero?)
    reason_codes << (deductuble_code unless service_co_insurance.to_f.zero?)
    reason_codes << (copay_code unless service_co_pay.to_f.zero?)
    reason_codes << (noncovered_code unless service_no_covered.to_f.zero?)
    reason_codes << (discount_code unless service_discount.to_f.zero?)
    reason_codes << (contractual_code unless contractual_amount.to_f.zero?)
    reason_codes << (denied_code unless denied.to_f.zero?)
    reason_codes << (primary_payment_code unless primary_payment.to_f.zero?)
    reason_codes = reason_codes.compact
    reason_codes
  end
  
  def get_remark_codes
    ansi_remark_codes.map(&:adjustment_code)
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
  
  
  # Calculating processor_input_field_count in svc level
  # by checking constant fields in grid as well as configured fields populated
  # through FCUI.
  def processor_input_field_count(facility, insurance_eob)
    total_field_count_with_data = 0
    payment_code_fields_with_data = []
    configured_amount_fields = []
    constant_fields = [service_quantity, service_modifier1,
      service_modifier2, service_modifier3, service_modifier4, 
      copay_reason_code_id, coinsurance_reason_code_id, 
      contractual_reason_code_id, deductible_reason_code_id,
      discount_reason_code_id, noncovered_reason_code_id, primary_payment_reason_code_id]
    constant_amount_fields = [service_allowable, service_no_covered,
      service_discount, service_co_insurance, service_deductible, service_co_pay,
      primary_payment, contractual_amount]
    constant_charge_and_payment_fields = [service_procedure_charge_amount,
      service_paid_amount]
    fc_ui_date_fields = [date_of_service_from, date_of_service_to]
    fc_ui_fields = [service_procedure_code, bundled_procedure_code, revenue_code,
      denied_reason_code_id, rx_number, service_provider_control_number,
      line_item_number, payment_status_code, pbid, retention_fees,
      service_prepaid, prepaid_reason_code_id, service_plan_coverage,
      patient_responsibility, pr_reason_code_id]
    expected_payment_field = [expected_payment]
    payment_code_fields = [inpatient_code, outpatient_code]
    
    payment_code_fields_with_data = payment_code_fields.select{|field|
      !field.blank?}.compact
    
    unless payment_code_fields_with_data.blank?
      if payment_code_fields_with_data.include?("1,2")
        total_field_count_with_data += 2
      else
        total_field_count_with_data += 1
      end
    end
    
    configured_date_fields = fc_ui_date_fields.select{|field|
      facility.details[:service_date_from]}
    configured_amount_fields << denied if facility.details[:denied]
    configured_amount_fields << drg_amount if facility.details[:drg_amount]
    
    total_other_fields = constant_fields + fc_ui_fields + configured_date_fields +
      constant_charge_and_payment_fields
    total_amount_fields = constant_amount_fields + configured_amount_fields +
      expected_payment_field

    total_other_fields_with_data = total_other_fields.select{|field| !field.blank?}
    total_amount_fields_with_data = total_amount_fields.select{|field|
      !field.blank? and field != 0.00}
    
    total_field_count_with_data += total_other_fields_with_data.length +
      total_amount_fields_with_data.length
    total_field_count_with_data += service_payment_eobs_ansi_remark_codes.length if facility.details[:remark_code]
    total_field_count_with_data += service_payment_eobs_reason_codes.length if $IS_PARTNER_BAC
    
    if service_allowable.blank? && insurance_eob == true &&
        facility.details[:interest_in_service_line]
      if facility.details[:service_date_from]
        total_field_count_with_data -= 4
      else
        total_field_count_with_data -= 2
      end
    end
    
    total_field_count_with_data
  end
  
  def svc_adjustments_elements
    [[service_co_insurance, coinsurance_code, coinsurance_code_description, coinsurance_groupcode],
      [service_deductible, deductuble_code, deductuble_code_description, deductuble_groupcode],
      [service_co_pay, copay_code, copay_code_description, copay_groupcode],
      [service_no_covered, noncovered_code, noncovered_code_description, noncovered_groupcode],
      [service_discount, discount_code, discount_code_description, discount_groupcode],
      [primary_payment, primary_payment_code, primary_payment_code_description, primary_payment_groupcode],
      [denied, denied_code, denied_code_description, denied_groupcode],
      [contractual_amount, contractual_code, contractual_code_description, contractual_groupcode]]
  end
  
  def service_xml(xml, index, service_payment_count, claim_index, transaction_index, facility)
    procedure_code, qualifier = get_normalized_codes_and_qualifiers(facility)
    
    xml.service(:ID => service_payment_count + 1) do
      xml.tag!(:claim_payment_attrib, claim_index + 1)
      xml.tag!(:tran_attrib, transaction_index + 1)
      xml.tag!(:batch_attrib, 1)
      xml.tag!(:service_line_no, index + 1 )
      xml.tag!(:service_qualifier_cd, qualifier)
      xml.tag!(:procedure_cd, procedure_code)
      xml.tag!(:charge_am, sprintf('%.02f', service_procedure_charge_amount.to_f))
      xml.tag!(:payment_am, sprintf('%.02f', service_paid_amount.to_f))
      xml.tag!(:service_start_dt, date_of_service_from)
      xml.tag!(:service_end_dt, date_of_service_to)
      xml.tag!(:revenue_cd, revenue_code)
    end
    service_payment_count += 1
  end
  
  def service_adjustment_xml(xml, service_payment_count, facility, payer, service_adjustment_count)
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
      adjustment_qt = (service_quantity.blank? ? 0 : service_quantity)
      if !amount.to_f.zero? && !reason_code.blank? && !group_code.blank?
        xml.service_adjustment(:ID => service_adjustment_count + 1) do
          xml.tag!(:service_attrib, service_payment_count + 1)
          xml.tag!(:payer_reason_cd, reason_code)
          xml.tag!(:claim_adjustment_group_cd, group_code)
          xml.tag!(:claim_adjustment_reason_cd, mapped_code)
          xml.tag!(:adjustment_am, sprintf('%.02f', amount.to_f))
          xml.tag!(:adjustment_qt, adjustment_qt)
          xml.tag!(:client_system_cd, client_code)
          xml.tag!(:reporting_activity_1_tx, (crosswalked_codes[:reporting_activity1]))
          xml.tag!(:reporting_activity_2_tx, (crosswalked_codes[:reporting_activity2]))
        end
        service_adjustment_count += 1
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
              codes_and_descriptions_to_notify << [code, description, service_payment_count + 1]
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
    service_payment_count += 1
    return service_adjustment_count, service_payment_count, codes_and_descriptions_to_notify
  end

  #This method returns the hash of md5-hash and ids
  def self.get_the_service_payment_eobs_hash eob_id
    query = "SELECT id,CASE WHEN (service_procedure_charge_amount IS NOT NULL AND service_procedure_code IS NOT NULL AND date_of_service_from IS NOT NULL) THEN MD5(CONCAT(service_procedure_charge_amount,service_procedure_code,date_of_service_from)) WHEN (service_procedure_charge_amount IS NOT NULL AND service_procedure_code IS NOT NULL AND date_of_service_from IS NULL) THEN MD5(CONCAT(service_procedure_charge_amount,service_procedure_code)) ELSE 0 END AS 'md5_hash' FROM service_payment_eobs WHERE insurance_payment_eob_id = #{eob_id}"
    service_lines = self.find_by_sql(query)
    svc_line_hash = {}
    service_lines.each do |svc|
      svc_line_hash[svc.md5_hash] = svc.id
    end
    return svc_line_hash
  end

  def service_disallowed
    return (service_no_covered.to_f + service_discount.to_f + denied.to_f + contractual_amount.to_f )
  end
  
  # Returns whether the payment amount is zero or not
  def zero_payment?
    service_paid_amount.to_f.zero?
  end
  
  # Provides the service line which have reason codes
  #
  # Input :
  # type : array of service lines of a particular eob
  #
  # Output :
  # Returns the service line which have reason codes
  def find_service_line_having_reason_codes(service_payment_eobs)
    service_payment_eobs.reverse.each do |service_payment|
      adjustment_reason_elements.each do |element|
        if service_payment.send("#{element}_reason_code_id")
          return service_payment
        end
      end
    end
    return nil
  end
    
  # Formats service_procedure_code, qualifier
  # based on business rules for printing them
  # in XML, 835 outputs.
  # Possible candiate to be reused for the purpose of
  # displying Human Readable 835 View, in future.
  # Input :
  # facility : facility of the batch to which this service line belongs to
  # Output :
  # Formatted service_procedure_code, qualifier
  def get_normalized_codes_and_qualifiers(facility)
    is_dental_facility = false
    if facility.details.has_key?('physician_facility')
      is_dental_facility = !facility.details[:physician_facility]
    end
    
    if !service_procedure_code.blank?
      procedure_code = service_procedure_code.strip.upcase
      if procedure_code[0..1] == 'ZZ'
        procedure_code = procedure_code[2..5]
        qualifier = 'ZZ'
      else
        qualifier = is_dental_facility ? 'AD' : 'HC'
      end
    elsif !revenue_code.blank?
      qualifier = 'NE'
    end
    return procedure_code, qualifier
  end
  
  #This is for getting all primary reason code ids associated to a service line.
  def get_primary_reason_code_ids_of_svc
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

  def get_value(eob_value,claim_value)
    unless claim_value.blank?
      val = claim_value
    else
      val = eob_value
    end
  end

  def get_class(eob_value,claim_value,column)
    unless claim_value.blank?
      val = "imported"
    else
      val = self.style(column)
    end
    val
  end

  def is_orphan_adjustment_code?(facility, adjustment_reason)
    facility.details[:cas_segment_for_orphan_adjustment_code] &&
      self.send("#{adjustment_reason}_amount").blank? &&
      (self.send("#{adjustment_reason}_reason_code_id").present? ||
        self.send("#{adjustment_reason}_hipaa_code_id").present?)
  end

end
