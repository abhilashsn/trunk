# Code Audited On 06/10/11
require 'utils/rr_logger'
class ReasonCode < ActiveRecord::Base

  validates_length_of :reason_code, :maximum => 15, :message => "Reason Code should have length upto 15."
  validates_length_of :reason_code_description, :maximum => 2500, :message => "Reason Code should have length upto 2500."
  validates_presence_of :reason_code, :message => "Reason Code is mandatory."
  validate :validate_reason_code

  has_many :reason_codes_clients_facilities_set_names, :dependent => :destroy
  has_many :reason_codes_ansi_remark_codes, :dependent => :destroy
  has_many :eob_reason_codes, :dependent => :destroy
  has_many :ansi_remark_codes, :through => :reason_codes_ansi_remark_codes
  has_many :service_payment_eobs_reason_codes, :dependent => :destroy
  has_many :service_payment_eobs, :through => :service_payment_eobs_reason_codes
  has_many :insurance_payment_eobs_reason_codes, :dependent => :destroy
  has_many :insurance_payment_eobs, :through => :insurance_payment_eobs_reason_codes
  has_many :facilities, :through => :reason_codes_clients_facilities_set_names
  has_many :clients, :through => :reason_codes_clients_facilities_set_names
  has_many :reason_codes_jobs, :dependent => :destroy
  has_many :jobs, :through => :reason_codes_jobs
  belongs_to :reason_code_set_name
  belongs_to :check_information

  after_create :create_unique_code
  before_save :upcase_grid_data
  after_update :record_changed_values

  alias_attribute :code, :reason_code
  alias_attribute :description, :reason_code_description

  def get_unique_code
    (unique_code || 'RM_' + id.to_s(36)).upcase
  end

  def normalized_unique_code
    unique_code = get_unique_code #.to_s.upcase
    if !unique_code.blank?
      'RM_' + unique_code
    end
  end

  def get_rc_page_number rc_id, job_id
    eob_rc_record = EobReasonCode.where("reason_code_id = ? and job_id = ? and active  = 1", rc_id, job_id)
    unless eob_rc_record.blank?
      page_no = eob_rc_record.last.page_no
    else
      job = Job.find_by_id(job_id)
      parent_job_exists = !job.parent_job_id.blank?
    
      if parent_job_exists
        jobid =  job.parent_job_id
      else
        child_job_exists = Job.exists?(:parent_job_id => job.parent_job_id)
        jobid = job.id if child_job_exists
      end

      unless jobid.blank?
        job_ids = Job.where(:parent_job_id => jobid).map(&:id)
        job_ids << jobid
        rc_page_records = EobReasonCode.where("reason_code_id = ? and job_id in (?) and active  = 1",rc_id, job_ids)
        rc_page_nos = rc_page_records.map(&:page_no).compact.uniq unless rc_page_records.blank?
        page_no = rc_page_nos.first  unless rc_page_nos.blank?
      end
    end
    page_no
  end

  def normalized_unique_code_for_upmc
    unique_code = get_unique_code #.to_s.upcase
    if !unique_code.blank?
      unique_code = unique_code.slice(3..-1)
      'BNY' + unique_code
    end
  end

  def record_changed_values
    JobActivityLog.record_changed_values(self)
  end

  # TODO: Jojith - for code presentation.
  def map_ansi_code(ansi_remark_codes)
    ansi_codes = ansi_remark_codes.split(',')
    ansi_remark_codes = find_ansi_remark_codes(ansi_codes)
    self.destroy_ansi_codes_if_necessary(ansi_codes, ansi_remark_codes)
    unless ansi_remark_codes.nil?
      self.ansi_remark_codes << ansi_remark_codes
    end
  end

  # TODO: Jojith - Method can be removed
  def find_ansi_remark_codes(ansi_codes)
    AnsiRemarkCode.find_all_by_adjustment_code(ansi_codes)
  end

  def destroy_ansi_codes_if_necessary(ansi_codes,ansi_remark_codes)
    if !ansi_remark_codes.empty? or ansi_codes.blank?
      self.reason_codes_ansi_remark_codes.destroy_all
    end
  end

  def self.create_reason_code_and_map_codes payer, params
    reason_code = ReasonCode.find_or_create_by_reason_code_and_reason_code_description_and_reason_code_set_name_id(params["reason"]["code"],
      params["reason_code"]["description"],
      payer.reason_code_set_name_id)
    reason_code.update_attribute("status", "ACCEPT")

    if (params["hipaa"]["code"].present? ||  params["client"]["code"].present?)
      rccfsn = ReasonCodesClientsFacilitiesSetName.find_or_create_by_reason_code_id_and_client_id_and_facility_id(reason_code.id,
        nil,nil)
      rccfsn.associate_hippa_and_client_codes(params)
    end
    remark_codes_to_associate = params[:optional_ansi_remark_codes].to_s.split(",")
    crosswalked_rc_remark_code_id = params[:remark_code_crosswalk_ids].to_s.split(",")
    associate_client_and_facility_ids = {
      :facility_id => params[:facility_id],
      :client_id => params[:client_id]
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :rc_remark_code_ids => crosswalked_rc_remark_code_id,
      :facility_id => params[:remark_code_crosswalked_facility_id],
      :client_id => params[:remark_code_crosswalked_client_id]
    }
    associate_remark_codes(remark_codes_to_associate, associate_client_and_facility_ids,
      remark_code_crosswalked_and_client_and_facility_ids)
  end

  # This de-activates the remark code crosswalk records
  # Input :
  # crosswalked_client_id : Client Id of the crosswalk record to identify the level of crosswalk to delete
  # crosswalked_facility_id : Facility Id of the crosswalk record to identify the level of crosswalk to delete
  # Output :
  # Sets the active indicator as 0 of the crosswalk records chosen
  # Sets the remark_code_crosswalk_flag of reason code to 0 if it has no other remark code crosswalks
  def delete_remark_code_crosswalk(crosswalked_client_id, crosswalked_facility_id)
    crosswalked_condition = "active_indicator = 1 AND reason_code_id = #{id}"
    if crosswalked_facility_id
      crosswalked_client_and_facility_level_condition = " AND facility_id = #{crosswalked_facility_id}"
    elsif crosswalked_client_id
      crosswalked_client_and_facility_level_condition = " AND client_id = #{crosswalked_client_id} AND facility_id IS NULL"
    else
      crosswalked_client_and_facility_level_condition = " AND client_id IS NULL AND facility_id IS NULL"
    end
    if !crosswalked_client_and_facility_level_condition.blank?
      crosswalked_condition += crosswalked_client_and_facility_level_condition
      ReasonCodesAnsiRemarkCode.where(crosswalked_condition).update_all(:active_indicator => false, :updated_at => Time.now)
    end
    remark_code_crosswalks = ReasonCodesAnsiRemarkCode.where(:reason_code_id => id, :active_indicator => true)
    if remark_code_crosswalks.length == 0
      ReasonCode.where(:id => id).update_all(:remark_code_crosswalk_flag => false, :updated_at => Time.now)
    end
  end

  # Crosswalk the remark codes to the reason code in facility, client and global level
  # The multiple remark code adjustment codes are crosswalked to the reason code
  # Input :
  # remark_adjustment_codes : Array of remark code adjustment codes to crosswalk
  # associate_client_and_facility_ids : Hash containing the client_id and facility_id to crosswalk
  # remark_code_crosswalked_and_client_and_facility_ids : Hash containing the crosswalked reason_codes_remark_codes.id,
  # crosswalked client_id, crosswalked facility_id
  # This is mainly used because the UI for crosswalking allows to edit across the different levels of crosswalk.
  # Output :
  # remark_code_crosswalk_flag in reason_codes is set as 1 if the crosswalk exists else 0
  # Saves the crosswalk association in ReasonCodesAnsiRemarkCode
  # Sets the active indicator as 1 of the crosswalk records chosen to crosswalk, else sets to 0
  def associate_remark_codes(remark_codes_to_associate, associate_client_and_facility_ids = {},
      remark_code_crosswalked_and_client_and_facility_ids = {})

    if !remark_code_crosswalked_and_client_and_facility_ids.blank?
      crosswalked_rc_remark_code_ids = remark_code_crosswalked_and_client_and_facility_ids[:rc_remark_code_ids]
      crosswalked_facility_id = remark_code_crosswalked_and_client_and_facility_ids[:facility_id]
      crosswalked_client_id = remark_code_crosswalked_and_client_and_facility_ids[:client_id]
    end

    if !associate_client_and_facility_ids.blank?
      facility_id_to_crosswalk = associate_client_and_facility_ids[:facility_id]
      client_id_to_crosswalk = associate_client_and_facility_ids[:client_id]
    end

    rc_remark_code_records, remark_code_ids_to_delete = [], []
    remark_code_records_to_associate, remark_code_ids_to_associate = [], []

    not_the_same_global_level_record = (!crosswalked_rc_remark_code_ids.blank? &&
        crosswalked_facility_id.blank? && crosswalked_client_id.blank? &&
        (!facility_id_to_crosswalk.blank? || !client_id_to_crosswalk.blank?))
    not_the_same_facility_level_record = (!crosswalked_facility_id.blank? &&
        (crosswalked_facility_id.to_i != facility_id_to_crosswalk.to_i))
    not_the_same_client_level_record = (!crosswalked_client_id.blank? &&
        (crosswalked_client_id.to_i != client_id_to_crosswalk.to_i || !facility_id_to_crosswalk.blank?))

    crosswalked_condition = "active_indicator = 1 AND reason_code_id = #{id}"

    # De-activate the crosswalks if the crosswalk level is edited to another level
    if not_the_same_global_level_record || not_the_same_facility_level_record || not_the_same_client_level_record
      if !crosswalked_facility_id.blank?
        crosswalked_client_and_facility_level_condition = " AND facility_id = #{crosswalked_facility_id}"
      elsif !crosswalked_client_id.blank?
        crosswalked_client_and_facility_level_condition = " AND client_id = #{crosswalked_client_id} AND facility_id IS NULL"
      elsif !not_the_same_global_level_record.blank?
        crosswalked_client_and_facility_level_condition = " AND client_id IS NULL AND facility_id IS NULL"
      end
      if !crosswalked_client_and_facility_level_condition.blank?
        crosswalked_condition += crosswalked_client_and_facility_level_condition
        ReasonCodesAnsiRemarkCode.where(crosswalked_condition).update_all(:active_indicator => false, :updated_at => Time.now)
      end
    end

    if !remark_codes_to_associate.blank?
      remark_code_records_to_associate = AnsiRemarkCode.where("adjustment_code IN (?)", remark_codes_to_associate).select("id")
      remark_code_ids_to_associate = remark_code_records_to_associate.map(&:id)
    end

    # Activates the de-activated existing crosswalk records
    if !facility_id_to_crosswalk.blank?
      client_and_facility_level_condition = " AND facility_id = #{facility_id_to_crosswalk}"
    elsif !client_id_to_crosswalk.blank?
      client_and_facility_level_condition = " AND client_id = #{client_id_to_crosswalk} AND facility_id IS NULL"
    else
      client_and_facility_level_condition = " AND client_id IS NULL AND facility_id IS NULL"
    end
    condition = "active_indicator = 0 AND reason_code_id = #{id}"
    condition += client_and_facility_level_condition
    ReasonCodesAnsiRemarkCode.where(condition).update_all(:active_indicator => true, :updated_at => Time.now)

    # Creates new crosswalk records
    condition = "reason_code_id = #{id}"
    condition += client_and_facility_level_condition
    associated_rc_remark_code_records = ReasonCodesAnsiRemarkCode.where(condition).select("id, ansi_remark_code_id")
    associated_remark_code_ids = associated_rc_remark_code_records.map(&:ansi_remark_code_id)
    associated_remark_code_ids_to_delete = associated_remark_code_ids
    remark_code_records_to_associate.each do |remark_code_to_associate|
      if !associated_remark_code_ids.include?(remark_code_to_associate.id)
        rc_remark_code_record = ReasonCodesAnsiRemarkCode.new
        rc_remark_code_record.reason_code_id = id
        rc_remark_code_record.ansi_remark_code_id = remark_code_to_associate.id
        rc_remark_code_record.facility_id = facility_id_to_crosswalk
        rc_remark_code_record.client_id = client_id_to_crosswalk
        rc_remark_code_record.active_indicator = true
        rc_remark_code_records << rc_remark_code_record

      elsif !remark_code_ids_to_associate.include?(remark_code_to_associate.id)
        remark_code_ids_to_delete << remark_code_to_associate.id
      end
      associated_remark_code_ids_to_delete.delete(remark_code_to_associate.id)
    end
    if !rc_remark_code_records.blank?
      ReasonCodesAnsiRemarkCode.import rc_remark_code_records
    end

    # De-activate the crosswalks if the remark codes are deleted from a level
    remark_code_ids_to_delete << associated_remark_code_ids_to_delete
    remark_code_ids_to_delete = remark_code_ids_to_delete.flatten.compact.uniq
    if !remark_code_ids_to_delete.blank?
      condition = "ansi_remark_code_id IN (#{remark_code_ids_to_delete.join(',')})"
      condition += client_and_facility_level_condition
      ReasonCodesAnsiRemarkCode.where(condition).update_all(:active_indicator => false, :updated_at => Time.now)
    end

    # Setting or re-setting the remark_code_crosswalk_flag based on the active remark code crosswalks
    remark_code_crosswalk_length = ReasonCodesAnsiRemarkCode.count(:conditions => ["reason_code_id = #{id} AND active_indicator = 1"])
    if remark_code_crosswalk_length == 0
      self.remark_code_crosswalk_flag = 0 if remark_code_crosswalk_flag != 0
    else
      self.remark_code_crosswalk_flag = 1 if remark_code_crosswalk_flag != 1
    end
    if self.changed?
      self.save
    end
  end

  # Obtain the facility or client or global level crosswalked remark code adjustment codes in an array
  # Input :
  # client_id : Client Id to determine the level of crosswalk
  # facility_id : Facility Id to determine the level of crosswalk
  # Output :
  # remark_codes : Array of crosswalked remark code adjustment codes
  # remark_code_crosswalk_ids : Array of crosswalked reason_codes_remark code Ids
  def get_remark_codes(client_id = nil, facility_id = nil)
    remark_codes, remark_code_crosswalk_ids = [], []
    if remark_code_crosswalk_flag
      condition = "active_indicator = 1 AND reason_codes.id = #{id}"
      if !facility_id.blank?
        condition += " AND reason_codes_ansi_remark_codes.facility_id = #{facility_id}"
      elsif !client_id.blank?
        condition += " AND reason_codes_ansi_remark_codes.client_id = #{client_id} AND reason_codes_ansi_remark_codes.facility_id is NULL"
      else
        condition += " AND reason_codes_ansi_remark_codes.facility_id is NULL AND reason_codes_ansi_remark_codes.client_id is NULL"
      end
      remark_code_records = ReasonCodesAnsiRemarkCode.select('ansi_remark_codes.adjustment_code,
        reason_codes_ansi_remark_codes.id AS remark_code_crosswalk_id').
        where(condition).
        joins("INNER JOIN ansi_remark_codes ON ansi_remark_codes.id = reason_codes_ansi_remark_codes.ansi_remark_code_id \
        INNER JOIN reason_codes ON reason_codes.id =  reason_codes_ansi_remark_codes.reason_code_id")

      remark_codes = remark_code_records.map(&:adjustment_code)
      remark_code_crosswalk_ids = remark_code_records.map(&:remark_code_crosswalk_id)
    end
    return remark_codes, remark_code_crosswalk_ids
  end

  # TODO: Jojith - Search by reason_code_description can be a full text search

  # This method is used to create new RCs and Descriptions and their mappings if they are new. If the RCs are already present, they will be mapped with client,facility and payer in this method..
  def self.save_reason_code_and_association(payer, reason_code, reasoncode_desc, check_number, client_id = nil, facility_id = nil, source = 'RM')
    is_partner_bac = $IS_PARTNER_BAC
    if not is_partner_bac
      client_id = nil
      facility_id = nil
    end
    if payer.footnote_indicator
      reasoncode =  ReasonCode.find_by_reason_code_description(reasoncode_desc)
    else
      reasoncode =  ReasonCode.find_by_reason_code_and_reason_code_description(reason_code, reasoncode_desc)
    end
    if reasoncode.blank?
      reasoncode = ReasonCode.new(:reason_code => reason_code, :reason_code_description => reasoncode_desc)
      reasoncode.reason_codes_clients_facilities_set_names.build({:payer_id => payer.id, :client_id => client_id,:facility_id => facility_id, :check_number => check_number, :source => source })
      reasoncode.save!
      if payer.footnote_indicator and reasoncode.save
        reasoncode.update_attributes!(:reason_code => reasoncode.id)
      end
    else
      rc_association = reasoncode.reason_codes_clients_facilities_set_names.find_by_reason_code_id_and_client_id_and_facility_id_and_payer_id(reasoncode.id, client_id, facility_id, payer.id)
      if rc_association.blank?
        rc_association = ReasonCodesClientsFacilitiesSetName.create!(:reason_code_id => reasoncode.id, :payer_id => payer.id,:client_id => client_id, :facility_id => facility_id, :check_number => check_number, :source => source)
      end
    end
    return reasoncode.id
  end

  # TODO: Suma - Current logic can be handle in reason_codes collection DB query level.
  def self.count_of_reason_codes_with_one_description(reason_codes)
    count_of_reason_codes = 0
    unless reason_codes.blank?
      reason_codes.each do |rc|
        if (reason_codes.index(rc) == reason_codes.rindex(rc))
          count_of_reason_codes += 1
        end
      end
    end
    count_of_reason_codes
  end
  # +-------------------------------------------------------------------+
  # This method is for getting unique codes, separated by semicolon(;). |
  # Input  : An array of reason code IDs and reason_code records.       |
  # Output : A string of Unique codes , separated by semicolon(;).      |
  # +-------------------------------------------------------------------+
  def self.get_unique_codes_for(reason_code_informations, reason_code_ids)
    unique_codes = []
    unless reason_code_ids.blank?
      reason_code_ids.each do |rc_id|
        reason_code_informations.each do |reason_code_info|
          if rc_id == reason_code_info.id
            if !reason_code_info.active && !reason_code_info.replacement_reason_code_id.blank?
              reason_code_info = ReasonCode.find(reason_code_info.replacement_reason_code_id)
            end
            unique_codes << reason_code_info.get_unique_code
            break
          end
        end
      end
    end
    unique_codes.blank? ? "" : unique_codes.join(";")
  end

  def self.get_vaild_reason_codes(reason_code_ids)
    valid_reason_codes = []
    actual_reason_codes = ReasonCode.find(reason_code_ids)
    actual_reason_codes.each do |rc|
      if !rc.active && !rc.replacement_reason_code_id.blank?
        valid_reason_codes << ReasonCode.find(rc.replacement_reason_code_id)
      else
        valid_reason_codes << rc
      end
    end
    valid_reason_codes.sort.reverse
  end

  # Obtain the reason code record for search / creation / updation
  # For classified payer, the code or description with set name has to be unique.
  # For un-classified payer, the code or description with set name need not be unique.
  # Two modules call this method : DC Grid and WebService reasoncode update
  # DC Grid will provide payer and its set name, Webservice only provide the set name
  # Input : search parameters
  # code : reason code
  # description : reason code description
  # set_name : reason code set name
  # payer : payer [optional]
  # Output :
  # Obtained reason code object
  def self.get_reason_code(code, description, set_name, payer = nil)
    if !set_name.blank?
      payer = payer || Payer.find_by_reason_code_set_name_id(set_name.id, :select => ['status'])
      if !code.blank?
        conditions = "reason_code_set_name_id = #{set_name.id} and \
          unique_code NOT IN ('1','2','3','4','5') and active = 1 and "
        reason_code_searched_for_unclassified_payer = false
        payer_status = payer.status.to_s.upcase if payer
        # payer_status blank is applicable when we create rcs with new payer from grid.
        # Then the payer is not created but it is assumed to be.
        if payer_status.blank? || payer_status == 'NEW' || payer_status == 'CLASSIFIED_BY_DEFAULT'
          reason_code_object = self.get_reason_code_for_unclassified_payer(code, description, conditions)
          reason_code_searched_for_unclassified_payer = true
        end
        if !reason_code_searched_for_unclassified_payer
          reason_code_object = self.get_reason_code_for_classified_payer(code, description, set_name, conditions)
        end
      end
    end
    reason_code_object.marked_for_deletion = false unless reason_code_object.blank?
    reason_code_object
  end

  # Returns the reason code object for an un-classified payer
  # For un-classified payer, the code or description with set name need not be unique.
  # Input :
  # code : reason code
  # description : reason code description
  # conditions : conditions for search
  # Output :
  # Obtained reason code object
  def self.get_reason_code_for_unclassified_payer(code, description, conditions)
    ReasonCode.find(:first, :conditions => [conditions +
          "reason_code = ? and reason_code_description = ?", code, description])
  end

  # Returns the reason code object for a classified payer
  # For classified payer, the code or description with set name should be unique.
  # Input :
  # code : reason code
  # description : reason code description
  # set_name : reason code set name
  # conditions : conditions for search
  # Output :
  # Obtained reason code object
  def self.get_reason_code_for_classified_payer(code, description, set_name, conditions)
    if set_name.is_footnote?
      self.get_reason_code_for_footnote_payer(code, description, conditions)
    else
      self.get_reason_code_for_nonfootnote_payer(code, conditions)
    end
  end

  # Returns the reason code object for a classified footnote payer
  # Input :
  # code : reason code
  # description : reason code description
  # conditions : conditions for search
  # Output :
  # Obtained reason code object
  def self.get_reason_code_for_footnote_payer(code, description, conditions)
    logger.info "\n The code obtained is a footnote code #{code}."
    if code.start_with?('RM_')
      unique_code = code.slice(3..-1)
      ReasonCode.find(:first,
        :conditions => [conditions + "unique_code = ?", unique_code])
    elsif !description.blank?
      ReasonCode.find(:first,
        :conditions => [conditions + "reason_code_description = ?", description])
    end
  end

  # Returns the reason code object for a classified non-footnote payer
  # Input :
  # code : reason code
  # conditions : conditions for search
  # Output :
  # Obtained reason code object
  def self.get_reason_code_for_nonfootnote_payer(code, conditions)
    logger.info "\n The code obtained is a reason code #{code}."
    ReasonCode.find(:first, :conditions => [conditions + "reason_code = ?", code])
  end


  # Update the reason code object with the new code, description and status.
  # Input :
  # inbound_code : incoming code(new or existing)
  # inbound_description : incoming description(new or existing)
  # set_name : reason code set name
  # Output :
  # Updated reason code object
  def save_reason_code(inbound_code, inbound_description, set_name)
    if !set_name.blank?
      is_footnote = set_name.is_footnote?
      non_footnote_payer_condition = !is_footnote && !inbound_code.blank?
      if !self.id.blank?
        non_footnote_payer_condition = non_footnote_payer_condition && !inbound_description.blank?
      end
      footnote_payer_condition = is_footnote && !inbound_description.blank? &&
        !inbound_code.blank?
      if non_footnote_payer_condition
        self.code = inbound_code.upcase
      elsif footnote_payer_condition
        self.code = inbound_code.upcase if self.id.blank?
      end
      if non_footnote_payer_condition || footnote_payer_condition
        self.description = inbound_description.upcase
        self.reason_code_set_name_id = set_name.id
      end
      if self.code.blank? || self.description.blank?
        self.status = 'NEW'
      else
        self.status = 'ACCEPT'
      end
      if self.changed? && self.valid?
        self.save
        self.reload
      end
      self if !self.id.blank?
    end
  end

  # Creates the reason codes with code, description, check_number and set name
  # Input :
  # code : reason code
  # description : reason code description
  # check_number : check_number of the check where this is first seen
  # set_name : reason code set name
  # Output :
  # Created reason code object
  def self.create_reason_code(code, description, parameters = {})
    reason_code = ReasonCode.create!(:reason_code => code,
      :reason_code_description => description,
      :status => "NEW", :check_information_id => parameters[:check_id],
      :reason_code_set_name_id => parameters[:set_name_id], :check_number => parameters[:check_number],
      :payer_name => parameters[:payer_name], :job_id => parameters[:job_id],
      :facility_name => parameters[:facility_name], :batchid => parameters[:batchid],
      :batch_date => parameters[:batch_date])
    reason_code
  end

  # Update the reason code object with the new code, description, check_number & status.
  # Input :
  # reason_code_value : reason code
  # reason_code_description : reason code description
  # payer_footnote_indicator : footnote indicator of payer
  #check_number : check_number of the check where this is first seen
  # Output :
  # true / false
  def update_reason_code(reason_code_value, reason_code_description, payer_footnote_indicator, check_information_id)
    if payer_footnote_indicator
      condition_for_update = self.reason_code.to_s.strip != reason_code_value &&
        self.status.upcase != "ACCEPT"
      if condition_for_update
        self.reason_code = reason_code_value
        self.check_information_id = check_information_id
      end
    else
      condition_for_update = self.reason_code_description.to_s.strip != reason_code_description &&
        self.status.upcase != "ACCEPT"
      if condition_for_update
        self.reason_code_description = reason_code_description
        self.check_information_id = check_information_id
      end
    end
    self.save!
  end

  def is_associated_somewhere?
    count = ReasonCodesJob.count(:conditions => ["reason_code_id = ?", id])
    count = ReasonCodesClientsFacilitiesSetName.count(:conditions => ["reason_code_id = ?", id]) if count == 0
    count = ReasonCodesAnsiRemarkCode.count(:conditions=> ["reason_code_id = ?",id]) if count == 0
    return count != 0
  end

  #This method is for getting the id of default reason codes.
  def self.get_default_reason_code_ids(is_facility_horizon_eye)
    hash_with_rc_info = Hash.new
    hash_with_rc_info["decuctible"] = ["1", "Deductible Amount", "1", nil]
    hash_with_rc_info["coinsurance"] = ["2", "Coinsurance Amount", "2", nil]
    hash_with_rc_info["copay"] = ["3", "Co-payment Amount", "3", nil]

    if is_facility_horizon_eye
      hash_with_rc_info["primary_payment"] = ["46", "This service is not covered", "4", nil]
    else
      hash_with_rc_info["primary_payment"] = ["23", "The impact of prior payer(s) adjudication including payments and/or adjustments", "4", nil]
    end
    hash_with_rc_info
  end

  # Groups the reason codes belonging to this payer by column name passed in as an argument
  # all records except first are soft deleted from each group
  # Input:
  # reason_codes : collection of reason_codes to be updated
  # grouping_param : this can be one of the following attributes of the reason code object,
  #  reason_code or reason_code_description
  # Output: True/ False indicating if all the clean up activities were successful
  def self.cleanup_duplicate_reason_codes_group_by(reason_codes, grouping_param)

    if self.column_names.include?(grouping_param)
      success = true
      retained_rc_ids = []
      replacement_and_duplicate_rc_ids = Hash.new
      group_by_attribute = "#{grouping_param}"
      rc_groups = reason_codes.group_by do |rc|
        rc.send(group_by_attribute).to_s.upcase
      end

      rc_groups.each do |group, rcs|
        if rcs.length > 0
          retained_rc_id = rcs.delete_at(0).id
          retained_rc_ids << retained_rc_id
          replacement_and_duplicate_rc_ids[retained_rc_id] = rcs.map(&:id)
        end
      end
      if !retained_rc_ids.blank?
        success &&= self.where(:id => retained_rc_ids).update_all(:active => 1, :replacement_reason_code_id => nil, :updated_at => Time.now)
      end
      if !replacement_and_duplicate_rc_ids.blank?
        replacement_and_duplicate_rc_ids.each do |replacement_rc_id, duplicate_rc_ids|
          duplicate_rc_ids = duplicate_rc_ids.flatten.compact
          unless duplicate_rc_ids.blank?
            success &&= self.where("id != #{replacement_rc_id} AND id in (?)",duplicate_rc_ids).update_all(:active => 0, :replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
            success &&= self.where("id != #{replacement_rc_id} AND replacement_reason_code_id in (?)",duplicate_rc_ids).update_all(:replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
          end
        end
      end
    end
    if success != false && !success.nil?
      true
    end
  end

  def self.cleanup_duplicate_default_reason_codes(default_rcs)
    success = true
    retained_rc_ids = []
    replacement_and_duplicate_rc_ids = Hash.new
    rc_groups = default_rcs.group_by do |rc|
      rc.unique_code.to_s.upcase
    end
    rc_groups.each do |group, rcs|
      if rcs.length > 1
        first_retained_rc = rcs.first
        retained_rc_id = first_retained_rc.id
        rcs.delete(first_retained_rc)
        retained_rc_ids << retained_rc_id
        replacement_and_duplicate_rc_ids[retained_rc_id] = rcs.map(&:id)
      end
    end
    if !retained_rc_ids.blank?
      success &&= self.where(:id => retained_rc_ids).update_all(:active => 1, :replacement_reason_code_id => nil, :updated_at => Time.now)
    end
    if !replacement_and_duplicate_rc_ids.blank?
      replacement_and_duplicate_rc_ids.each do |replacement_rc_id, duplicate_rc_ids|
        duplicate_rc_ids = duplicate_rc_ids.flatten.compact
        success &&= self.where(:id => duplicate_rc_ids).update_all(:active => 0, :replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
        success &&= self.where(:replacement_reason_code_id => duplicate_rc_ids).update_all(:replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
      end
    end
    if success != false && !success.nil?
      true
    end
  end

  # Groups the reason codes belonging to this payer by column name passed in as an argument
  # retains the first mapped record or first accepted or just the first record,
  # soft deletes all other reason codes from each group
  # Input:
  # reason_codes : collection of reason_codes to be updated
  # grouping_param : this can be one of the following attributes of the reason code object,
  #  reason_code or reason_code_description
  # Output: True/ False indicating if all the clean up activities were successful
  def self.cleanup_duplicate_reason_codes_retain_mapped_or_accepted_or_first(reason_codes, grouping_param)
    if self.column_names.include?(grouping_param)
      success = true
      retained_rc_ids = []
      replacement_and_duplicate_rc_ids = Hash.new
      group_by_attribute = "#{grouping_param}"
      rc_groups = reason_codes.group_by do |rc|
        rc.send(group_by_attribute).to_s.upcase
      end
      rc_groups.each do |group, rcs|
        if rcs.length > 0
          accepted_rcs = rcs.select{|rc| rc.status == 'ACCEPT'}
          mapped_rcs = rcs.select{|rc| rc.reason_codes_clients_facilities_set_names.length > 0}
          retained_rcs = mapped_rcs + accepted_rcs + rcs
          first_retained_rc = retained_rcs.first
          retained_rc_id = first_retained_rc.id
          rcs.delete(first_retained_rc)
          retained_rc_ids << retained_rc_id
          replacement_and_duplicate_rc_ids[retained_rc_id] = rcs.map(&:id)
        end
      end

      if !replacement_and_duplicate_rc_ids.blank?
        replacement_and_duplicate_rc_ids.each do |replacement_rc_id, duplicate_rc_ids|
          duplicate_rc_ids = duplicate_rc_ids.flatten.compact
          if !duplicate_rc_ids.blank?
            success &&= self.where("id != #{replacement_rc_id} AND id in (?)",duplicate_rc_ids).update_all(:active => 0, :replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
            success &&= self.where("id != #{replacement_rc_id} AND replacement_reason_code_id in (?)",duplicate_rc_ids).update_all(:replacement_reason_code_id => replacement_rc_id, :updated_at => Time.now)
          end
        end
      end
    end
    if success != false && !success.nil?
      true
    end
  end

  def self.get_the_replacements_for_inactive_reason_codes(reason_code_objects)
    replaced_reason_code_ids = []
    reason_code_objects.each do |rc_obj|
      if !rc_obj.replacement_reason_code_id.blank?
        replaced_reason_code_ids << rc_obj.replacement_reason_code_id
      end
    end
    replaced_reason_code_ids
  end

  # The attribute notify is set to 0
  # Input :
  # rc_ids_to_reset_notify : Ids of the reason code objects
  # Output :
  # Number of records updated
  def self.reset_notify(rc_ids_to_reset_notify)
    if !rc_ids_to_reset_notify.blank?
      self.where(:id => rc_ids_to_reset_notify).update_all(:notify => 0, :updated_at => Time.now)
    end
  end

  def footnoteCodeDto
    dto = ReasonCodeService::FootnoteCodeDto.new
    dto.code = normalized_unique_code
    dto.description = reason_code_description
    dto
  end

  # Validates and updates the reason codes by editing the reason code or its description
  # Performs validation for updation based on footnote indicator
  # IF the edited value belongs to an approved or accepted RC, then throw a validation error
  # If the edited value belongs to an unapproved RC, then cleanup the duplicates and update the value
  # For non-footnote payers, the code has to be unique, so duplicate codes are made inactive
  # For footnote payers, the description has to be unique, so duplicate codes are made inactive
  # Input :
  # footnote_indicator : footnote_indicator of payer
  # code_new_value : new adjustment code value for reason code
  # description_new_value : new description value for reason code
  def cleanup_for_editing_code_or_description(footnote_indicator, code_new_value, description_new_value, user_acceptance, current_user_id)
    is_user_acceptance_needed = false
    if !code_new_value.blank? && !description_new_value.blank?
      if (code_new_value.match(/^[A-Za-z0-9\-\.\_]*$/) &&
            !code_new_value.match(/\.{2}|\_{2}|\-{2}^[\-\.\_]+$/))
        if (!footnote_indicator && code_new_value != code) ||
            (footnote_indicator && description_new_value != description)

          attribute, value = attributes_based_on_footnote_indicator(footnote_indicator, code_new_value, description_new_value)
          existing_records = ReasonCode.select("id, reason_code, reason_code_description, status").
            where("#{attribute} = ? AND reason_code_set_name_id = ?",
            value, reason_code_set_name_id)
          set_new_value, mapped_or_accepted_record = cleanup_and_determine_the_value_to_edit(existing_records, attribute)
        else
          set_new_value = true
        end
        if user_acceptance == "true" && mapped_or_accepted_record
          is_user_acceptance_needed = true
        else
          edit_record_with_new_values(mapped_or_accepted_record, set_new_value, code_new_value, description_new_value, current_user_id)
        end
      else
        raise "Reason Code should contain alphabet, number, hyphen, underscore and period only"
      end
    else
      raise "Reason Code and Description cannot be blank"
    end
    return is_user_acceptance_needed
  end

  def self.find_active_record(rc_record, replacement_reason_code_id)
    while replacement_reason_code_id.present?
      logger.debug "The reason Code record having id #{rc_record.id} is a soft deleted one.
                    Hence obtaining the replaced reason code record having id #{replacement_reason_code_id}."
      rc_record = ReasonCode.find(replacement_reason_code_id)
      if rc_record
        replacement_reason_code_id = rc_record.replacement_reason_code_id
        reason_code_record = rc_record
      end
    end
    reason_code_record
  end

  def self.remove_cyclic_replacement_references(set_name_id = 413846)
    logger.debug "Analyzing reason code cyclic replacement references"
    if set_name_id
      records = ReasonCode.where("replacement_reason_code_id IS NOT NULL AND reason_code_set_name_id = :set_name_id " , {:set_name_id => set_name_id})
      if records.length > 0
        reason_code_ids_and_replacements_hash = build_hash_of_reason_code_ids_and_their_replacements(records)
        cyclic_pattern_of_reason_code_ids = build_cyclic_pattern_of_reason_code_ids(reason_code_ids_and_replacements_hash)
        active_and_inactive_reason_code_ids_hash = build_active_and_inactive_reason_code_ids(cyclic_pattern_of_reason_code_ids)
        update_reason_code_records_to_remove_cyclic_replacement_references(active_and_inactive_reason_code_ids_hash)
      end
    end
  end

  private

  def self.build_hash_of_reason_code_ids_and_their_replacements(records)
    reason_code_ids_and_replacements_hash = {}
    if records.length > 0
      records.each do |record|
        reason_code_ids_and_replacements_hash[record.id] = record.replacement_reason_code_id
        if reason_code_ids_and_replacements_hash[record.replacement_reason_code_id].blank?
          reason_code_ids_and_replacements_hash[record.replacement_reason_code_id] = nil
        end
      end
    end
    logger.debug "Hash of reason_code_ids_and_replacements_hash : #{reason_code_ids_and_replacements_hash}"
    reason_code_ids_and_replacements_hash
  end

  def self.build_cyclic_pattern_of_reason_code_ids(reason_code_ids_and_replacements_hash = {})
    cyclic_pattern_of_reason_code_ids = []
    reason_code_ids_and_replacements_hash.each do |key, value|
      cyclic_pattern_of_reason_code_ids << [key, value]
      reason_code_ids_and_replacements_hash.delete(key)
      new_value = reason_code_ids_and_replacements_hash[value]
      new_key = value
      while new_value != nil
        cyclic_pattern_of_reason_code_ids.each_with_index do |element, index|
          if element[-1] == new_key
            cyclic_pattern_of_reason_code_ids[index] = cyclic_pattern_of_reason_code_ids[index] << new_value
            reason_code_ids_and_replacements_hash.delete(new_key)
            new_key = new_value
            new_value = reason_code_ids_and_replacements_hash[new_value]
          end
        end
      end
    end
    logger.debug "Array of cyclic_pattern_of_reason_code_ids : #{cyclic_pattern_of_reason_code_ids}"
    cyclic_pattern_of_reason_code_ids
  end

  def self.build_active_and_inactive_reason_code_ids(array_of_replacements = [])
    active_and_inactive_reason_code_ids_hash = {}
    if array_of_replacements.present?
      array_of_replacements.each do |active_and_inactive_reason_code_ids|
        inactive_reason_code_ids = []
        if active_and_inactive_reason_code_ids[0] == active_and_inactive_reason_code_ids[-1]
          length = active_and_inactive_reason_code_ids.length
          active_and_inactive_reason_code_ids.each_with_index do |element, index|
            inactive_reason_code_ids << element if index != 0 && index != length - 1
          end

          active_and_inactive_reason_code_ids_hash[active_and_inactive_reason_code_ids[0]] = inactive_reason_code_ids
        end
      end
    end
    logger.debug "Hash of active_and_inactive_reason_code_ids_hash : #{active_and_inactive_reason_code_ids_hash}"
    active_and_inactive_reason_code_ids_hash
  end

  def self.update_reason_code_records_to_remove_cyclic_replacement_references(active_and_inactive_reason_code_ids_hash = {})
    if active_and_inactive_reason_code_ids_hash.present?
      logger.debug "Reason code cyclic replacement references are found"
      logger.debug "active_and_inactive_reason_code_ids_hash : #{active_and_inactive_reason_code_ids_hash}"
      active_reason_code_ids = active_and_inactive_reason_code_ids_hash.keys
      logger.debug "active_reason_code_ids : #{active_reason_code_ids}"
      ReasonCode.where(:id => active_reason_code_ids).update_all(:active => true, :replacement_reason_code_id => nil, :updated_at => Time.now)
      active_and_inactive_reason_code_ids_hash.each do |active_reason_code_id, inactive_reason_code_ids|
        ReasonCode.where(:id => inactive_reason_code_ids).update_all(:active => false, :replacement_reason_code_id => active_reason_code_id, :updated_at => Time.now)
      end
    end
  end
  
  # Unique code is an alphanumeric Base 36 of Primary Key Id
  def create_unique_code
    if self.unique_code.blank?
      self.unique_code = 'RM_' + id.to_s(36).upcase
      self.save
    end
  end

  # +--------------------------------------------------------------------------+
  # This method is for validating Reason Code                                  |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # +--------------------------------------------------------------------------+
  def validate_reason_code
    error_message = ""
    if !reason_code.blank? && (reason_code.match(/\.{2}|\_{2}|\-{2}|^[\-\.\_]+$/) ||
          !reason_code.match(/^[A-Za-z0-9\-\.\_]*$/))
      error_message += "Reason Code should contain Alphanumeric, hyphen, underscore and period only!"
    end

    errors.add(:base, error_message) unless error_message == ""
  end

  # Predicate method to find if there is a mapped or accepted record present from a collection
  # Input :
  # reason_code_records : Collection of reason code records
  def self.find_mapped_or_accepted_record(reason_code_records)
    mapped_or_accepted_record = nil
    reason_code_records.each_with_index do |rc_record, index|
      if rc_record.status == 'ACCEPT' || rc_record.status == 'MAPPED'
        mapped_or_accepted_record = rc_record
        break
      end
    end
    logger.debug "is_accepted_rc_present : #{mapped_or_accepted_record.id if mapped_or_accepted_record}"
    mapped_or_accepted_record
  end

  def upcase_grid_data
    self.attributes.each_pair do |k,v|
      eval("self.#{k} = self.#{k}.dup.upcase") if v.is_a?(String) && !['1','2','3','4','5'].include?(self.unique_code)
    end
  end

  def attributes_based_on_footnote_indicator(footnote_indicator, code, description)
    if footnote_indicator
      attribute = 'reason_code_description'
      value = description
    else
      attribute = 'reason_code'
      value = code
    end
    return attribute, value
  end

  def cleanup_and_determine_the_value_to_edit(existing_records, attribute)
    logger.debug "cleanup_and_determine_the_value_to_edit"
    reason_code_records_for_cleanup = []
    if existing_records.present?
      logger.debug "The existing records with the same attribute values, IDs : #{existing_records.map(&:id) if existing_records}"
      mapped_or_accepted_record = ReasonCode.find_mapped_or_accepted_record(existing_records)
      if mapped_or_accepted_record.blank?
        reason_code_records_for_cleanup << self << existing_records
        reason_code_records_for_cleanup = reason_code_records_for_cleanup.flatten
        ReasonCode.cleanup_duplicate_reason_codes_retain_mapped_or_accepted_or_first(reason_code_records_for_cleanup, attribute)
        ReasonCode.remove_cyclic_replacement_references(reason_code_set_name_id)
        set_new_value = true
      end
    end
    return set_new_value, mapped_or_accepted_record
  end

  def edit_record_with_new_values(mapped_or_accepted_record, set_new_value, code_new_value, description_new_value, current_user_id)
    if mapped_or_accepted_record.present?
      associate_code_and_description(mapped_or_accepted_record.reason_code, mapped_or_accepted_record.reason_code_description)
      self.replacement_reason_code_id = mapped_or_accepted_record.id
      self.active = false
      ActivityLog.create(:object_id => self.id, :actor_id => current_user_id,
        :action => "Reason code is replaced with #{mapped_or_accepted_record.id}")
    elsif set_new_value
      associate_code_and_description(code_new_value, description_new_value)
    end
    if self.changed?
      self.save
    end
  end

  def associate_code_and_description(code, description)
    self.reason_code = code
    self.reason_code_description = description
  end

end
