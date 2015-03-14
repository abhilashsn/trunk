# -*- coding: utf-8 -*-
class MicrLineInformation < ActiveRecord::Base
  include DcGrid
  belongs_to :payer
  has_many :check_informations
  has_many :facilities_micr_informations
  validates_presence_of :aba_routing_number
  validates_presence_of :payer_account_number
  has_one :payer_exclusion
  validates_uniqueness_of :aba_routing_number, :scope => [:payer_account_number],
    :message => "There's already a record with the supplied ABA and DDA Numbers"
  NEW = "NEW"
  APPROVED = "APPROVED"

  after_update :create_qa_edit
  before_save do |obj|
    obj.upcase_grid_data(['status'])
  end
  
  def create_qa_edit
    QaEdit.create_records(self)
  end

  def self.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility_commercial_payerid)
    aba_routing_number = aba_routing_number.to_s.gsub(/[\D]/, '').justify(9,'0')
    payer_account_number = payer_account_number.to_s.gsub(/[\D]/, '')
    are_micr_values_valid = !aba_routing_number.blank? && !aba_routing_number.to_i.zero? &&
      !payer_account_number.blank? && !payer_account_number.to_i.zero?
    if are_micr_values_valid      
      micr_record = self.find_by_aba_routing_number_and_payer_account_number(
        aba_routing_number, payer_account_number)
      temp_payid = facility_commercial_payerid || 'D9998'
      if micr_record.blank?
        micr_record = self.create(
          :aba_routing_number => aba_routing_number, :payer_account_number => payer_account_number , :payid_temp => temp_payid)
      elsif micr_record.payid_temp.blank?
        micr_record.payid_temp = temp_payid
        micr_record.save
      end
    end
    micr_record
  end
  
  def self.micr_record(aba_routing_number,payer_account_number)
    return MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(aba_routing_number,payer_account_number)
  end

  def self.allmicrs
    select("m.*, min(b.target_time) as target_time ").joins("m INNER JOIN payers p ON p.id = m.payer_id INNER JOIN check_informations c ON c.payer_id = p.id INNER JOIN jobs j ON j.id = c.job_id INNER JOIN batches b ON b.id = j.batch_id")
  end

  def self.micrs_eligible_for_payer_encounter_service_call page = 1
    relation = allmicrs.where(" p.status != 'NEW' AND p.status != 'Mapped' AND (m.status = 'NEW' OR m.status ='APPROVED') AND p.payer_type != 'patpay'")
    unless $IS_PARTNER_BAC
      relation = relation.where("p.status != 'Approved'")
    end    
    relation.group("m.id, p.id").order("target_time ASC").paginate(:page=>page)
  end

  def self.new_micr_records page = 1
    relation = allmicrs.where(" p.status != 'NEW' AND p.status != 'Mapped' AND (m.status = 'NEW' OR m.status ='APPROVED') AND p.payer_type = 'patpay'")
    unless $IS_PARTNER_BAC
      relation = relation.where("p.status != 'Approved'")
    end    
    relation.group("m.id, p.id").order("target_time ASC").paginate(:page=>page)    
  end

  def self.approved_micr_records
    self.joins("m INNER JOIN payers p ON p.id=m.payer_id").where("(m.status = 'New' OR m.status = 'APPROVED') AND  p.status != 'New' AND p.status != 'Mapped' AND p.status = 'Approved' AND p.payer_type != 'patpay'")

  end


  # If A/c # and Routing # not present in the Index file and Processor manually indexes A/c # and Routing #,
  #system match up successful – ie. finds payer details,
  #then Payer details auto populated on blur of payer account number field.
  def self.micr_wise_payer_details(micr_data, client, facility)
    micr_wise_payer_details = {}
    if(!micr_data.blank?)
      micr_wise_payer_info = micr_data.split(',')
      micr_information = MicrLineInformation.micr_record(micr_wise_payer_info[0], micr_wise_payer_info[1])
      if(!micr_information.blank?)
        if(!micr_information.payer_id.blank?)
          micr_wise_payer_information = Payer.find(micr_information.payer_id)
          micr_wise_payer_details["payer_id"] =  micr_wise_payer_information.id
          micr_wise_payer_details["payer"] =  micr_wise_payer_information.payer
          micr_wise_payer_details["payer_address_one"] = micr_wise_payer_information.pay_address_one
          micr_wise_payer_details["payer_address_two"] = micr_wise_payer_information.pay_address_two
          micr_wise_payer_details["payer_city"] = micr_wise_payer_information.payer_city
          micr_wise_payer_details["payer_state"] = micr_wise_payer_information.payer_state
          micr_wise_payer_details["payer_zip"] = micr_wise_payer_information.payer_zip
          micr_wise_payer_details["payer_tin"] = micr_wise_payer_information.payer_tin
          plan_type_config = facility.plan_type.to_s.upcase
          if plan_type_config == 'PAYER SPECIFIC ONLY'
            plan_type = micr_wise_payer_information.normalized_plan_type(client.id, facility.id, facility.details[:default_plan_type])
            micr_wise_payer_details["plan_type"] = plan_type if !plan_type.blank?
          end
          micr_wise_payer_details["payer_type"] = micr_wise_payer_information.payer_type
          micr_wise_payer_details["payer_status"] = micr_wise_payer_information.status
          micr_wise_payer_details["reason_code_set_name_id"] = micr_wise_payer_information.reason_code_set_name_id
        end
      end
      return micr_wise_payer_details.to_json
    else
      return "Newpayer"
    end
  end
  
  # Calculating processor_input_field_count in micr level
  # by checking configured fields populated through FCUI.
  def processor_input_field_count(facility)
    total_field_count_with_data = 0
    fc_ui_fields = [aba_routing_number, payer_account_number]
    configured_fields = fc_ui_fields.select{|field| facility.details[:micr_line_info]}
    configured_fields_with_data = configured_fields.select{|field| !field.blank?}
    total_field_count_with_data = configured_fields_with_data.length
    total_field_count_with_data
  end
  
  #update the temp_pay_id of micr and temp_gateway and reason_code_set_name of payer form the results
  #payer status is set to UNMAPPED
  def update_temp_payer_details results
    if results["successIndicator"]
      if self.payer
        self.update_attributes({:payid_temp => results["originalPayerId"], :status => "APPROVED"})
        self.payer.update_temp_payer_details results
      else
        false
      end
    else
      false
    end     
  end

  def update_payer_and_gateway_defaults
    if self.payer
      self.update_attribute("payid_temp","D9998")
      self.payer.update_attribute("gateway_temp", "HLSC")
    end
  end

  #update the payer infor for the micr all call the method to change the check associaiton for payer
  def update_payer_info newpayer, mapping
    self.payer = newpayer
    self.payid_temp = mapping.original_payer_id
    self.status = 'ACCEPT'
    is_micr_saved = self.valid? ? self.save : false
    if not is_micr_saved
      logger.debug "\n Save failed due to invalid MICR record. "
      errors.each_full { |msg| logger.debug msg }
    else
      logger.debug "\n MICR successfully saved"
    end
    is_micr_saved      
  end

end
