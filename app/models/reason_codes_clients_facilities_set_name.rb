class ReasonCodesClientsFacilitiesSetName < ActiveRecord::Base
  belongs_to :client
  belongs_to :facility
  belongs_to :reason_code
  belongs_to :hipaa_code
  belongs_to :denied_hipaa_code, :class_name => 'HipaaCode', :foreign_key => 'denied_hipaa_code_id'
  has_many :reason_codes_clients_facilities_set_names_client_codes, :include => [:client_code]
  has_many :client_codes, :through => :reason_codes_clients_facilities_set_names_client_codes
  has_many :denied_client_codes, :source => :denied_client_code,
    :through => :reason_codes_clients_facilities_set_names_client_codes
  has_many :insurance_payment_eobs
  has_many :service_payment_eobs

  attr_accessor :crosswalk_level


  validates_uniqueness_of :client_id, :scope => [:reason_code_id, :active_indicator],
    :message => "There can be only one mapping record for a combination of a reason code and client",
    :if => Proc.new{|rccfsn| rccfsn.facility_id.nil? && rccfsn.client_id.present? && rccfsn.active_indicator != 0}

  validates_uniqueness_of :facility_id, :scope => [:reason_code_id, :active_indicator],
    :message => "There can be only one mapping record for a combination of a reason_code and facility",
    :if => Proc.new{|rccfsn| rccfsn.client_id.nil? && rccfsn.facility_id.present? && rccfsn.active_indicator != 0}

  validates_uniqueness_of :reason_code_id, :scope => [:facility_id, :client_id, :active_indicator],
    :message => "There can be only one global level mapping record  for a reason_code",
    :if => Proc.new{|rccfsn| rccfsn.client_id.nil? && rccfsn.facility_id.nil? && rccfsn.active_indicator != 0}

  

  validate :other_dependencies
  
  scope :by_reason_code, lambda {|reason_code|
    unless reason_code.blank?
      { :conditions => ["reason_code_id = ?", reason_code.id] }
    else
      { :conditions => [] }
    end
  }
  
  scope :by_reason_codes, lambda {|reason_codes|
    unless reason_codes.blank?
      { :conditions => ["reason_code_id in (?)", reason_codes.map { |rc| rc.id}] }
    else
      { :conditions => [] }
    end
  }
  scope :by_client, lambda {|client|
    unless client.blank?
      { :conditions => ["client_id = ?", client.id] }
    else
      { :conditions => [] }
    end
  }
  scope :by_facility, lambda {|facility|
    unless facility.blank?
      { :conditions => ["facility_id = ?", facility.id] }
    else
      { :conditions => [] }
    end
  }
  
  scope :at_global_level, lambda {
    { :conditions => ["facility_id is NULL and client_id is NULL"] }
  }  

  def self.map_codes(mapping_parameters)
    reason_code = ReasonCode.find(mapping_parameters[:reasoncode_id])
    client_facility_payer_reasoncode = self.find_by_reason_code_id(reason_code.id)
    client_facility_payer_reasoncode = self.create(:reason_code_id => reason_code.id, :active_indicator => true) unless client_facility_payer_reasoncode
    manage_codes(client_facility_payer_reasoncode,mapping_parameters)
  end

  def self.manage_codes(client_facility_payer_reasoncode,mapping_parameters)
    manage_client_code(client_facility_payer_reasoncode,mapping_parameters) if $IS_PARTNER_BAC
    manage_hipaa_code(client_facility_payer_reasoncode,mapping_parameters)
    manage_ansi_code(client_facility_payer_reasoncode,mapping_parameters)
  end
  
  def self.manage_ansi_code(client_facility_payer_reasoncode,mapping_parameters)
    client_facility_payer_reasoncode.reason_code.map_ansi_code(mapping_parameters[:optional_ansi_remark_codes])
  end
  
  def self.manage_client_code(client_facility_payer_reasoncode,mapping_parameters)
    client_code = find_client_code(mapping_parameters)
    destroy_client_codes_if_necessary(client_facility_payer_reasoncode,mapping_parameters,client_code)
    unless client_code.nil?
      client_facility_payer_reasoncode.client_codes << client_code
    end
  end
  
  def self.manage_hipaa_code(client_facility_payer_reasoncode,mapping_parameters)
    hipaa_code = find_hipaa_code(mapping_parameters)
    destroy_hipaa_codes_if_necessary(client_facility_payer_reasoncode,mapping_parameters, hipaa_code)
    client_facility_payer_reasoncode.update_attributes(:hipaa_code => hipaa_code) unless hipaa_code.nil?
  end
  
  
  def self.find_client_code(mapping_parameters)
    unless mapping_parameters[:client][:code].blank?
      ClientCode.map_client_code(mapping_parameters[:client][:code])
    end
  end
  
  def self.destroy_client_codes_if_necessary(client_facility_payer_reasoncode,mapping_parameters,client_code)
    if !client_code.nil? or mapping_parameters[:client][:code].blank?
      client_facility_payer_reasoncode.reason_codes_clients_facilities_set_names_client_codes.destroy_all
    end
  end
  
  def self.find_hipaa_code(mapping_parameters)
    unless mapping_parameters[:hipaa][:code].blank?
      HipaaCode.map_hipaa_code(mapping_parameters[:hipaa][:code])
    end
  end
  
  def self.destroy_hipaa_codes_if_necessary(client_facility_payer_reasoncode,mapping_parameters,hipaa_code)
    if !hipaa_code.nil? or mapping_parameters[:hipaa][:code].blank?
      client_facility_payer_reasoncode.hipaa_code_id = nil
      client_facility_payer_reasoncode.save
    end
  end
  
  def self.find_ansi_code(mapping_parameters)
    ansi_codes = mapping_parameters[:optional_ansi_remark_codes].split(',')
    unless ansi_codes.blank?
      AnsiRemarkCode.find_all_by_adjustment_code(ansi_codes)
    end
  end
  
  def self.validate_codes(mapping_parameters)
    client_codes = find_client_code(mapping_parameters)
    hipaa_codes = find_hipaa_code(mapping_parameters)
    ansi_code = find_ansi_code(mapping_parameters)
    conditions_for_flash_notice(client_codes,hipaa_codes,ansi_code,mapping_parameters)
  end
  
  def self.conditions_for_flash_notice(client_codes,hipaa_codes,ansi_code,mapping_parameters)
    if (client_codes.nil? and hipaa_codes.nil? and ansi_code.blank?) and (!mapping_parameters[:client][:code].blank? and !mapping_parameters[:hipaa][:code].blank? and !mapping_parameters[:optional_ansi_remark_codes].blank?)
      "1"
    elsif (client_codes.nil? and hipaa_codes.nil?) and (!mapping_parameters[:client][:code].blank? and !mapping_parameters[:hipaa][:code].blank?)
      "2"
    elsif (client_codes.nil? and ansi_code.blank?) and (!mapping_parameters[:client][:code].blank? and !mapping_parameters[:optional_ansi_remark_codes].blank?)
      "3"
    elsif (hipaa_codes.nil? and ansi_code.blank?) and (!mapping_parameters[:hipaa][:code].blank? and !mapping_parameters[:optional_ansi_remark_codes].blank?)
      "4"
    elsif client_codes.nil? and !mapping_parameters[:client][:code].blank?
      "5"
    elsif hipaa_codes.nil? and !mapping_parameters[:hipaa][:code].blank?
      "6"
    elsif ansi_code.blank? and !mapping_parameters[:optional_ansi_remark_codes].blank?
      "7"
    end
  end
  
  def self.get_payer_id(client_facility_payer_reasoncode_id)
    self.find(client_facility_payer_reasoncode_id).payer.id
  end

  def destroy_associated_codes
    self.reason_codes_clients_facilities_set_names_client_codes.destroy_all if $IS_PARTNER_BAC
    self.destroy
  end
  
  def client_code
    self.client_codes.first.adjustment_code rescue nil
  end
  
  def ansi_codes
    ansi_codes = []
    self.reason_code.ansi_remark_codes.each do |ansi_code|
      ansi_codes << ansi_code.adjustment_code
    end
    ansi_codes.join(',')
  end
  
  def save_crosswalks(crosswalk_item, reason_code, set_name, client = nil, facility = nil)
    if !set_name.blank? && !reason_code.blank? && !crosswalk_item.blank?
      self.reason_code = reason_code
      self.facility = facility
      self.client = client
      self.claim_status_code = crosswalk_item.claim_status_code if !crosswalk_item.claim_status_code.blank?
      self.denied_claim_status_code = crosswalk_item.denied_claim_status_code if !crosswalk_item.denied_claim_status_code.blank?
      self.reporting_activity1 = crosswalk_item.reporting_activity_code if !crosswalk_item.reporting_activity_code.blank?
      self.reporting_activity2 = crosswalk_item.reporting_activity_code2 if !crosswalk_item.reporting_activity_code2.blank?
      self.active_indicator = crosswalk_item.active
      client_code_saved, denied_client_code_saved = true, true

      if !crosswalk_item.ansi_code.blank?
        save_hipaa_code(crosswalk_item)
      end
      if !crosswalk_item.denied_ansi_code.blank?
        save_denied_hipaa_code(crosswalk_item)
      end
      crosswalk_saved = self.valid? ? self.save : false
      logger.info "\n Is crosswalk record saved ? #{crosswalk_saved}"
      
      if $IS_PARTNER_BAC && !crosswalk_item.client_system_code.blank?
        client_code_saved = save_client_code(crosswalk_item)
      end
      if $IS_PARTNER_BAC && !crosswalk_item.denied_client_system_code.blank?
        denied_client_code_saved = save_denied_client_code(crosswalk_item)
      end
      
      crosswalk_saved && client_code_saved && denied_client_code_saved
    end
  end
  
  def eligible_for_output?(eob)
    if active_indicator == false && !eob.blank?
      eob.created_at < updated_at
    elsif active_indicator == true
      true
    end
  end

  def get_crosswalk_level
    if self.client_id.blank? && self.facility_id.blank?
      "GLOBAL"
    elsif  self.client_id.present? && self.facility_id.blank?
      "CLIENT"
    else
      "FACILITY"
    end
  end

  def associate_hippa_and_client_codes(params)
    if $IS_PARTNER_BAC
      client_code = ClientCode.find_by_adjustment_code(params["client"]["code"])
      if client_code
        rccfsncc = ReasonCodesClientsFacilitiesSetNamesClientCode.find_by_reason_codes_clients_facilities_set_name_id_and_client_code_id(self.id,client_code.id) rescue nil
        rccfsnccs = ReasonCodesClientsFacilitiesSetNamesClientCode.find(:all,:conditions=>"reason_codes_clients_facilities_set_name_id = #{self.id}")
        (rccfsnccs - [rccfsncc]).map{|j| j.destroy}
        if !rccfsncc
          client_code.reason_codes_clients_facilities_set_names_client_codes << ReasonCodesClientsFacilitiesSetNamesClientCode.new({:reason_codes_clients_facilities_set_name_id => self.id})
        end
      elsif params["client"]["code"].blank?
        rccfsnccs = ReasonCodesClientsFacilitiesSetNamesClientCode.find(:all,:conditions=>"reason_codes_clients_facilities_set_name_id = #{self.id}")
        rccfsnccs.map{|j| j.destroy}
      end
    end
    hipaa_code = HipaaCode.find_by_hipaa_adjustment_code(params["hipaa"]["code"])
    if hipaa_code
      self.hipaa_code_id = hipaa_code.id
      self.save
    else
      self.destroy   unless params["id"].present?
      raise "Updation failed, Please enter existing HIPAA"
    end    
  end


  def sanitize_based_on_level_set
    if crosswalk_level.present?
      if crosswalk_level == 'GLOBAL'
        self.facility_id = nil; self.client_id = nil 
      elsif crosswalk_level == 'CLIENT'
        self.facility_id = nil 
      elsif crosswalk_level == 'FACILITY'
        self.client_id = nil         
      end
    end
  end

  def get_codes_crosswalked
    codes = {}    
    codes[:hipaa_code] = hipaa_code.hipaa_adjustment_code if !hipaa_code_id.blank?
    codes[:hipaa_group_code] = hipaa_group_code if hipaa_group_code.present?
    if $IS_PARTNER_BAC && client_codes.present?
      client_codes = self.reason_codes_clients_facilities_set_names_client_codes    
      codes[:client_code] = ClientCode.select("adjustment_code").find(client_codes.first.client_code_id).adjustment_code
    end
    codes
  end

  private

  def save_hipaa_code(crosswalk_item)
    hipaa_code =  HipaaCode.find_by_hipaa_adjustment_code_and_active_indicator(crosswalk_item.ansi_code, true)
    if !hipaa_code.blank?
      logger.info "\n Hipaa Code found : #{hipaa_code.hipaa_adjustment_code}"
      self.hipaa_code_id = hipaa_code.id
    else
      logger.info "\n Hipaa Code could not be found"
    end    
  end
  
  def save_denied_hipaa_code(crosswalk_item)
    denied_hipaa_code = HipaaCode.find_by_hipaa_adjustment_code_and_active_indicator(crosswalk_item.denied_ansi_code, true)
    if !denied_hipaa_code.blank?
      logger.info "\n Denied Hipaa Code found : #{denied_hipaa_code.hipaa_adjustment_code}"
      self.denied_hipaa_code_id = denied_hipaa_code.id
    else
      logger.info "\n Denied Hipaa Code could not be found"
    end
  end

  def save_client_code(crosswalk_item)
    is_client_code_saved = false
    client_code = ClientCode.find_or_create_by_adjustment_code(crosswalk_item.client_system_code)
    if !client_code.id.blank?
      logger.info "\n Client Code saved : #{client_code.adjustment_code}"
      client_association = ReasonCodesClientsFacilitiesSetNamesClientCode.find(:first,
        :conditions => ["reason_codes_clients_facilities_set_name_id =? and category =? ", id, 'NON-DENIED'])
      client_association ||= ReasonCodesClientsFacilitiesSetNamesClientCode.new
      client_association.reason_codes_clients_facilities_set_name_id = id
      client_association.client_code_id = client_code.id if !client_code.blank?
      client_association.category = 'NON-DENIED'
      is_client_code_saved = client_association.valid? ? client_association.save : false
      logger.info "\n Is client code association saved ? : #{is_client_code_saved}"
    else
      logger.info "\n Client Code could not be saved"
    end
    is_client_code_saved
  end

  def save_denied_client_code(crosswalk_item)
    is_denied_client_code_saved = false
    denied_client_code = ClientCode.find_or_create_by_adjustment_code(crosswalk_item.denied_client_system_code)
    if !denied_client_code.id.blank?
      logger.info "\n Denied Client Code saved : #{denied_client_code.adjustment_code}"
      denied_client_association = ReasonCodesClientsFacilitiesSetNamesClientCode.find(:first,
        :conditions => ["reason_codes_clients_facilities_set_name_id =? and category =? ", id, 'DENIED'])
      denied_client_association ||= ReasonCodesClientsFacilitiesSetNamesClientCode.new
      denied_client_association.reason_codes_clients_facilities_set_name_id = id
      denied_client_association.client_code_id = denied_client_code.id
      denied_client_association.category = 'DENIED'
      is_denied_client_code_saved = denied_client_association.valid? ? denied_client_association.save : false
      logger.info "\n Is denied client code association saved ? : #{is_denied_client_code_saved}"
    else
      logger.info "\n Denied Client Code could not be saved"
    end
    is_denied_client_code_saved
  end


  #checking whether all the other dependencies are met
  def other_dependencies
    
    if self.client_id.present? && self.facility_id.present?
      errors[:base] << "Both Facility and Client cannot be present at a time"   
    end      
    
    if crosswalk_level.present?
      conditions = ""
      if crosswalk_level == "GLOBAL"
        errors[:base] << "Facility and Client cannot be set when cross walk level is GLOBAL"  if self.facility_id.present? || self.client_id.present?        
        if self.id?
          conditions = "reason_code_id = #{self.reason_code_id} && facility_id is null && client_id is null && id != #{self.id}"
        else
          conditions = "reason_code_id = #{self.reason_code_id} && facility_id is null and client_id is null "
        end        
        
      elsif crosswalk_level == "CLIENT"        
        
        errors[:base] << "Only client can be set when cross walk level is CLIENT"  if self.facility_id.present? && self.client_id.blank?
        errors[:base] << "Please select a Client" if self.client_id.blank?        
        if self.id?
          conditions = "reason_code_id = #{self.reason_code_id} && client_id = #{self.client_id} && id != #{self.id}"        
        else
          conditions = "reason_code_id = #{self.reason_code_id} && client_id = #{self.client_id} "
        end        
        
      elsif crosswalk_level == "FACILITY"
        if self.id?
          conditions = "reason_code_id = #{self.reason_code_id} &&  facility_id = #{self.facility_id} && id != #{self.id}"        
        else
          conditions = "reason_code_id = #{self.reason_code_id} && facility_id = #{self.facility_id} "
        end        
        
        errors[:base] << "Only facility can be set when cross walk level is FACILITY"  if self.client_id.present? && self.facility_id.blank?
        errors[:base] << "Please select a Facility" if self.facility_id.blank?
      end
      
      if errors[:base].empty? && conditions.present? && ReasonCodesClientsFacilitiesSetName.where(conditions).count > 0
        additional_info = ""
        additional_info = " for the client selected" if crosswalk_level == "CLIENT"
        additional_info = " for the facility selected" if crosswalk_level == "Facility"
        errors[:base] << "A #{crosswalk_level} Level mapping already exists #{additional_info}";
      end

    end
  end

  
end
