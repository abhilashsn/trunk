# ==============================================================================
# ReasonCodeCrosswalk is responsible to find the appropriate crosswalked codes
#  for a bunch of reason codes in an adjustment reason or for a single reason code or for a single service line.
# It provides a hash containing all the crosswalked codes.
# This class will be logged daily at Rails.root/log/reason_code_crosswalk_log/ReasonCodeCrosswalk.log
# ==============================================================================
# ==============================================================================
# ------------------------------------------------------------------------------
# 1) Eg. to get crosswalked codes for a bunch of reason codes in an adjustment reason
# client = Client.find(<id>)
# facility = Facility.find(<id>)
# payer = Payer.find(<id>)
# entity = ServicePaymentEob.find(<id>) for service level EOBs
# or
# entity = InsurancePaymentEob.find(<id>) for claim level EOBs
# adjustment_reason should be one of 'coinsurance', 'contractual', 'copay', 'deductible',
#   'denied', 'discount', 'noncovered', 'primary_payment'
#
# rcc = ReasonCodeCrosswalk.new(payer, entity, client, facility)
# crosswalked_codes = rcc.get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
#
# Please obtain your required crosswalked_codes as follows :
#      crosswalked_codes[:hipaa_code]
#      crosswalked_codes[:client_code]
#      crosswalked_codes[:reason_code] - Contain the primary reason code
#      crosswalked_codes[:reason_code_description] - Contain the primary reason code description
#      crosswalked_codes[:all_reason_codes]
#      crosswalked_codes[:group_code]
#      crosswalked_codes[:remark_codes]
#      crosswalked_codes[:default_code]
#      crosswalked_codes[:cas_01]
#      crosswalked_codes[:cas_02]
#      crosswalked_codes[:claim_status_code]
#      crosswalked_codes[:denied_claim_status_code]
#      crosswalked_codes[:reporting_activity1]
#      crosswalked_codes[:reporting_activity2]
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 2) Eg. to get crosswalked codes for a reason code
# payer = Payer.find(<id>)
# reason_code_object = ReasonCode.find(<id>)
#
# rcc = ReasonCodeCrosswalk.new(payer)
# crosswalked_codes = rcc.get_crosswalked_codes_for_reason_code(reason_code_object)
#
# Please obtain your required crosswalked_codes as follows :
#
#      crosswalked_codes[:hipaa_code]
#      crosswalked_codes[:denied_hipaa_code]
#      crosswalked_codes[:hipaa_code_active_indicator]
#      crosswalked_codes[:denied_hipaa_code_active_indicator]
#      crosswalked_codes[:client_code]
#      crosswalked_codes[:denied_client_code]
#      crosswalked_codes[:reason_code]
#      crosswalked_codes[:unique_code]
#      crosswalked_codes[:footnote_code]
#      crosswalked_codes[:reason_code_description]
#      crosswalked_codes[:remark_codes]
#      crosswalked_codes[:crosswalk_record_active_indicator]
#      crosswalked_codes[:claim_status_code]
#      crosswalked_codes[:denied_claim_status_code]
#      crosswalked_codes[:reporting_activity1]
#      crosswalked_codes[:reporting_activity2]
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 3) Eg. to get crosswalked codes for all the adjustment reasons for an entity
# client = Client.find(<id>)
# facility = Facility.find(<id>)
# payer = Payer.find(<id>)
# entity = ServicePaymentEob.find(<id>) for service level EOBs
# or
# entity = InsurancePaymentEob.find(<id>) for claim level EOBs
# is_crosswalked_codes_needed = false : Provides only primary_reason_codes, primary_reason_code_descriptions,
# all_reason_codes, all_reason_code_descriptions in hash
# is_crosswalked_codes_needed = true : Provides all the crosswalked codes in the hash
# rcc = ReasonCodeCrosswalk.new(payer, nil, client, facility)
# crosswalked_codes = rcc.get_all_codes_for_entity(entity, is_crosswalked_codes_needed)
#
# Please obtain your required crosswalked_codes as follows :
# Each value element of the hash is an array of the unique respective codes as described by the key.
#    crosswalked_codes[:primary_reason_codes]
#    crosswalked_codes[:primary_reason_code_descriptions]
#    crosswalked_codes[:all_reason_codes]
#    crosswalked_codes[:all_reason_code_descriptions]
#    crosswalked_codes[:hipaa_codes]
#    crosswalked_codes[:client_codes]
#    crosswalked_codes[:group_codes]
#    crosswalked_codes[:remark_codes]
#    crosswalked_codes[:cas_01_codes]
#    crosswalked_codes[:cas_02_codes]
#    crosswalked_codes[:claim_status_codes]
#    crosswalked_codes[:denied_claim_status_codes]
#    crosswalked_codes[:reporting_activities_1]
#    crosswalked_codes[:reporting_activities_2]
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ==============================================================================

#TODO: The crosswalk records are not fetched wrt to BAC.
#To be perfected features :
# 1) The primary reason codes are not considered as top priority
#     to obtain the crosswalked codes among primary and secondary reason codes
# 2) Client code table normalization for one crosswalk code for one level
# 3) To include the client code fetching in method get_reason_code_and_crosswalk_records
# 4) fix unit tests for client codes

require 'adjustment_reason'
require 'utils/rr_logger'

class ReasonCodeCrosswalk

  include AdjustmentReason

  attr_accessor :client, :facility, :payer, :set_name, :entity, :reason_code_object,
    :adjustment_reason, :reason_codes, :mapping_code_factor, :is_partner_bac, :is_crosswalked

  def initialize(payer, entity = nil, client = nil, facility = nil, set_name = nil)
    @client = client if client
    @payer = payer
    @set_name = set_name || (payer.reason_code_set_name if payer)
    if @set_name.blank?
      raise "Set Name is missing for Payer : #{payer.payer if payer}"
    end
    if facility.present?
      @facility = facility
      @mapping_code_factor = facility.details[:cas_02].to_s.upcase
      @mapping_code_factor = 'HIPAA CODE' if facility.details[:rc_crosswalk_done_by_client]
      @default_mappings = get_default_mappings
    end
    @entity = entity
    @is_partner_bac = $IS_PARTNER_BAC
    @fetch_footnote_code = payer.present? && payer.footnote_indicator && (@is_partner_bac || @client && @client.name.upcase == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER")
    @zero_payment = entity.zero_payment? if entity
    rcc_log.debug "\n\n\nObtaining Reason Code Crosswalked codes at #{Time.now}."
    rcc_log.debug "Reason Code Set Name ID is : #{@set_name.id if @set_name}"
  end

  # Log for ReasonCodeCrosswalk
  def rcc_log
    @rcc_logger ||= RevRemitLogger.new_logger(LogLocation::RCCLOG)
  end

  # Obtain the default HIPAA Code and Group Code
  # Output :
  # default_mappings : A hash whose key values are the adjustment_reasons and its value is
  #   DefaultCodesForAdjustmentReason object of that adjustment reason
  def get_default_mappings
    default_codes_for_adjustment_reasons = DefaultCodesForAdjustmentReason.select("
        default_codes_for_adjustment_reasons.adjustment_reason, \
        default_codes_for_adjustment_reasons.group_code, \
        default_codes_for_adjustment_reasons.enable_crosswalk, \
        hipaa_codes.hipaa_adjustment_code, \
        hipaa_codes.active_indicator").
      joins("LEFT OUTER JOIN hipaa_codes ON hipaa_codes.id = default_codes_for_adjustment_reasons.hipaa_code_id").
      where("default_codes_for_adjustment_reasons.facility_id = ?", facility.id)
    default_mappings = {}
    if default_codes_for_adjustment_reasons.length > 0
      default_codes_for_adjustment_reasons.each do |default_code_record|
        adjustment_reason = default_code_record.adjustment_reason
        default_mappings[adjustment_reason.to_sym] = default_code_record
      end
    end
    default_mappings
  end

  # Obtaining the reason code and its description
  # Input :
  # crosswalked_codes : A hash containing all the relevant codes for a reason code belonging to an adjustment reason
  # Output :
  # reason_code : adjustment code of reason code
  # reason_code_description : description of reason code
  def get_reason_code_and_description(crosswalked_codes)
    if crosswalked_codes[:reason_code]
      reason_code = crosswalked_codes[:reason_code]
      reason_code_description = crosswalked_codes[:reason_code_description]
    end
    if reason_code.blank? && crosswalked_codes[:all_reason_codes]
      rc_and_desc = crosswalked_codes[:all_reason_codes].first
      if rc_and_desc.present?
        reason_code = rc_and_desc[0]
        reason_code_description = rc_and_desc[1]
      end
    end
    return reason_code, reason_code_description
  end

  # Obtains a hash containing all the relevant codes for a reason code belonging to an adjustment reason.
  # This method provides the relevant codes based on the business logic.
  # It calls a number of methods to build the hash.
  # Input :
  # adjustment_reason : One of the adjustment reasons of amount paid
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes for a reason code belonging to an adjustment reason
  def get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
    rcc_log.debug "Getting crosswalked codes for entity : #{entity.class if entity} having ID : #{entity.id if entity}."
    rcc_log.debug "Getting crosswalked codes for adjustment reason : #{adjustment_reason}."
    @adjustment_reason = adjustment_reason
    @default_mapping = @default_mappings[adjustment_reason.to_sym]
    reason_code_ids = get_reason_code_records_for_adjustment_reason(adjustment_reason)
    @reason_code_ids_from_entity = reason_code_ids
    rcc_log.debug "All reason_code_ids_from_entity........................ : #{@reason_code_ids_from_entity.join(',') if @reason_code_ids_from_entity}"
    hipaa_code_from_entity = get_hipaa_code_for_adjustment_reason(adjustment_reason)
    @hipaa_code_from_entity = hipaa_code_from_entity
    if hipaa_code_from_entity.present?
      build_crosswalked_codes(nil, hipaa_code_from_entity)
    elsif reason_code_ids.present?
      @crosswalk_records = get_reason_code_and_crosswalk_records(reason_code_ids)
      if @crosswalk_records && @crosswalk_records.length > 0
        code_ids, payer_codes = [], []
        @crosswalk_records.each do |rc|
          code_ids << rc.id
          payer_codes << rc.reason_code
        end
        rcc_log.debug "Active Reason Codes found : #{payer_codes.join(', ')},
                their IDs : #{code_ids.join(', ') }"
        is_crosswalk_enabled = @default_mapping.enable_crosswalk if @default_mapping.present?
        if @facility.details[:miscellaneous_adjustment_fields] && !is_crosswalk_enabled
          is_crosswalk_enabled = ['miscellaneous_one', 'miscellaneous_two'].include?(adjustment_reason)
        end
        if is_crosswalk_enabled
          primary_crosswalk_record, secondary_crosswalk_records = get_crosswalk_record_for_reason_codes(@crosswalk_records)
          if primary_crosswalk_record.present?
            build_crosswalked_codes(primary_crosswalk_record, nil, secondary_crosswalk_records)
          else
            get_codes_for_adjustment_reason_having_crosswalk_disabled
          end
        else
          get_codes_for_adjustment_reason_having_crosswalk_disabled
        end
      else
        rcc_log.debug "Reason Codes were not found for #{adjustment_reason}."
        rcc_log.debug "Thus providing the default codes."
        build_codes_for_adjustment_reason_having_no_reason_codes
      end
    else
      rcc_log.debug "Reason Codes were not found for #{adjustment_reason}."
      rcc_log.debug "Thus providing the default codes."
      build_codes_for_adjustment_reason_having_no_reason_codes
    end
  end

  # Obtains the hash containing all the relevant codes for a non-crosswalked reason code,
  #  belonging to an adjustment reason.
  # Output :
  # codes : A hash containing all the relevant codes
  def build_codes_for_adjustment_reason_having_crosswalk_disabled
    codes = {}
    codes[:all_reason_codes] = get_all_reason_codes_and_descriptions
    if not @code_norc_found
      codes[:reason_codes_and_descriptions] = reason_codes_and_descriptions
      codes[:reason_code] = normalized_reason_code
      codes[:reason_code_description] = normalized_reason_code_description
      codes[:default_group_code] = default_group_code
      codes[:group_code] = group_code
      codes[:remark_codes] = normalized_remark_codes
      codes[:default_code] = default_code
      codes[:primary_reason_code_id] = primary_reason_code_id
      codes[:secondary_codes] = get_all_secondary_codes(nil, codes)
      codes[:cas_01] = get_cas01_code(codes)
      codes[:cas_02] = get_cas02_code(codes)
      codes[:secondary_cas_01] = get_secondary_cas01_code(codes)
      codes[:secondary_cas_02] = get_secondary_cas02_code(codes)
    end
    codes
  end

  # Obtains the hash containing all the relevant codes for an adjustment reason having no reason codes.
  # Output :
  # codes : A hash containing all the relevant codes
  def build_codes_for_adjustment_reason_having_no_reason_codes
    codes = {}
    codes[:default_group_code] = default_group_code
    codes[:group_code] = group_code
    codes[:default_code] = default_code
    codes[:cas_01] = get_cas01_code(codes)
    codes[:cas_02] = get_cas02_code(codes)
    codes[:secondary_cas_01] = get_secondary_cas01_code(codes)
    codes[:secondary_cas_02] = get_secondary_cas02_code(codes)
    codes
  end

  # Obtains the hash containing all the relevant codes for a reason code
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes
  def get_crosswalked_codes_for_reason_code(reason_code_object)
    rcc_log.debug "Getting crosswalked codes for reason code having ID, #{reason_code_object.id if reason_code_object}."
    @reason_code_object = reason_code_object
    crosswalk_record = get_crosswalk_record_for_a_reason_code(reason_code_object)
    build_crosswalked_codes_for_a_reason_code(crosswalk_record)
  end

  # Obtains the hash containing all the relevant codes for a reason code at global level
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes
  def get_crosswalked_codes_for_a_reason_code_at_global_level(reason_code_object)
    rcc_log.debug "Getting crosswalked codes for reason code at global level having ID, #{reason_code_object.id if reason_code_object}."
    @reason_code_object = reason_code_object
    crosswalk_record = crosswalk_record_for_a_reason_code_at_global_level(reason_code_object)
    build_crosswalked_codes_for_a_reason_code(crosswalk_record)
  end

  # Obtains the hash containing all the relevant codes for a reason code at client level
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes
  def get_crosswalked_codes_for_a_reason_code_at_client_level(reason_code_object)
    rcc_log.debug "Getting crosswalked codes for reason code at client level having ID, #{reason_code_object.id if reason_code_object}."
    @reason_code_object = reason_code_object
    crosswalk_record = crosswalk_record_for_a_reason_code_at_client_level(reason_code_object)
    build_crosswalked_codes_for_a_reason_code(crosswalk_record)
  end

  # Obtains the hash containing all the relevant codes for a reason code at site / facility level
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes
  def get_crosswalked_codes_for_a_reason_code_at_site_level(reason_code_object)
    rcc_log.debug "Getting crosswalked codes for reason code at site level having ID, #{reason_code_object.id if reason_code_object}."
    @reason_code_object = reason_code_object
    crosswalk_record = crosswalk_record_for_a_reason_code_at_site_level(reason_code_object)
    build_crosswalked_codes_for_a_reason_code(crosswalk_record)
  end

  # Obtain the reason code records for an adjustment reason
  # Input :
  # adjustment_reason : One of the adjustment reasons of amount paid
  # Output :
  # reason_code_ids : an array of all the Ids of all primary and secondary reason codes of an adjustment reason
  def get_reason_code_records_for_adjustment_reason(adjustment_reason)
    @adjustment_reason = adjustment_reason
    ordered_reason_code_ids = []
    reason_code_ids = get_reason_code_ids(adjustment_reason)
    
    if reason_code_ids.present?
      rc_records = ReasonCode.where(:id => reason_code_ids)   
      ordered_records = get_ordered_reason_codes(reason_code_ids, rc_records)
    end
    ordered_reason_code_ids = ordered_records.map(&:id) if ordered_records
    rcc_log.debug "ordered_reason_code_ids : #{ordered_reason_code_ids}"
    ordered_reason_code_ids
  end

  def get_reason_code_ids(adjustment_reason)
    reason_code_ids = []
    adjustment_reason_code_id = "#{adjustment_reason}_reason_code_id"
    reason_code_id = entity.send(adjustment_reason_code_id)
    if reason_code_id.present?
      reason_code_ids << reason_code_id
      if facility.details[:multiple_reason_codes_in_adjustment_field]
        secondary_reason_code_records = entity.class.secondary_reason_codes_by_adjustment_reason(entity.id, adjustment_reason)
        reason_code_ids << secondary_reason_code_records.map(&:reason_code_id) if secondary_reason_code_records
      end
      reason_code_ids = reason_code_ids.flatten.compact.uniq
    end
    reason_code_ids
  end

  def get_ordered_reason_codes(reason_code_ids, rc_records)
    ordered_records = []
    reason_code_ids.each_with_index do |ordered_reason_code_id, ordered_index|
      if rc_records.length > 0
        rc_records.each do |rc_record|
          reason_code_record = rc_record
          replacement_reason_code_id = rc_record.replacement_reason_code_id
          if replacement_reason_code_id.present?
            active_record = ReasonCode.find_active_record(rc_record, replacement_reason_code_id)
            reason_code_record = active_record if active_record.present?
          end
          if ordered_reason_code_id == rc_record.id
            ordered_records[ordered_index] = reason_code_record
          end
        end
      end
    end
    ordered_records
  end

  # Obtain the reason code records for an adjustment reason
  # Input :
  # adjustment_reason : One of the adjustment reasons of amount paid
  # Output :
  # reason_code_ids : an array of all the Ids of all primary and secondary reason codes of an adjustment reason
  def get_hipaa_code_for_adjustment_reason(adjustment_reason)
    adjustment_hipaa_code_id = "#{adjustment_reason}_hipaa_code_id"
    hipaa_code_id_from_entity = entity.send(adjustment_hipaa_code_id)
    if hipaa_code_id_from_entity.present?
      hipaa_code_array  = HipaaCode.get_active_code_details_given_ids([hipaa_code_id_from_entity])
      if hipaa_code_array.present?
        hipaa_id_and_code_and_description = hipaa_code_array.first
        if hipaa_id_and_code_and_description.present?
          hipaa_code = hipaa_id_and_code_and_description[1]
        end
      end
    end
    hipaa_code = hipaa_code.to_s.upcase
    rcc_log.debug "Getting HIPAA code directly from the entity table : #{hipaa_code}"
    hipaa_code
  end

  # Obtains the reason code records with all the relevant and crosswalked code for HIPAA Code
  # Input :
  # reason_code_ids : an array of all the Ids of all primary and secondary reason codes of an adjustment reason
  # Output :
  # @crosswalk_records : reason code records with all the relevant and crosswalked code for HIPAA Code
  def get_reason_code_and_crosswalk_records(reason_code_ids)
    selection_fields = "reason_codes.id, \
                          reason_codes.reason_code, \
                          reason_codes.reason_code_description, \
                          reason_codes.unique_code, \
                          reason_codes.active, \
                          reason_codes.replacement_reason_code_id, \
                          reason_codes.remark_code_crosswalk_flag, \
                          reason_codes.notify, \
                          crosswalk_table.id AS crosswalk_record_id, \
                          crosswalk_table.client_id, \
                          crosswalk_table.facility_id, \
                          crosswalk_table.active_indicator AS crosswalk_active_indicator, \
                          crosswalk_table.hipaa_code_id, \
                          crosswalk_table.hipaa_group_code, \
                          hipaa_codes.hipaa_adjustment_code, \
                          hipaa_codes.active_indicator AS hipaa_code_active_indicator, \
                          crosswalk_table.claim_status_code, \
                          crosswalk_table.denied_claim_status_code, \
                          crosswalk_table.reporting_activity1, \
                          crosswalk_table.reporting_activity2, \
                          crosswalk_table.denied_hipaa_code_id"

    reason_code_and_crosswalk_records = ReasonCode.select(selection_fields).
      joins("LEFT OUTER JOIN reason_codes_clients_facilities_set_names crosswalk_table ON crosswalk_table.reason_code_id = reason_codes.id
        LEFT OUTER JOIN hipaa_codes ON hipaa_codes.id = crosswalk_table.hipaa_code_id").
      where("reason_codes.id IN (?)", reason_code_ids ).order("reason_codes.id")
    records_hash = {}
    reason_code_and_crosswalk_records.each do |record|
      if records_hash[record.id].blank?
        records_hash[record.id] = [record]
      else
        records_hash[record.id] << record
      end
    end
    crosswalk_records, @crosswalk_records = [], []
    reason_code_ids.each do |reason_code_id|
      crosswalk_records  << records_hash[reason_code_id]
    end
    @crosswalk_records = crosswalk_records.flatten.compact
    @crosswalk_records
  end

  # Obtains the crosswalk record from a collection of records which are objects of ReasonCode based on site / client / global level hierarchy
  # Input :
  # crosswalk_records : The collection of the object of ReasonCode containing the crosswalked codes of all levels
  # Output :
  # crosswalk_record : crosswalk record as an object of ReasonCode based on site / client / global level hierarchy
  def get_crosswalk_record_for_reason_codes(crosswalk_records)
    selected_crosswalk_records, facility_level_crosswalk_records = [], []
    client_level_crosswalk_records, global_level_crosswalk_records  = [], []
    crosswalk_records.each do |crosswalk_record|
      if crosswalk_record.active && crosswalk_record.crosswalk_active_indicator == 1 &&
          crosswalk_record.hipaa_code_id.present? && crosswalk_record.facility_id == facility.id
        rcc_log.debug "Obtaining Site Level Record"
        facility_level_crosswalk_records << crosswalk_record
        rcc_log.debug "Site Level Record ID : #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
        if !facility.details[:cas_for_all_multiple_reason_codes_in_adjustment_field]
          break
        end
      end
    end
    selected_crosswalk_records = facility_level_crosswalk_records if facility_level_crosswalk_records.present?
    if selected_crosswalk_records.blank?
      rcc_log.debug "Obtaining Client Level Record"
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.active && crosswalk_record.crosswalk_active_indicator == 1 &&
            crosswalk_record.hipaa_code_id.present? && crosswalk_record.facility_id.blank? && crosswalk_record.client_id == client.id
          client_level_crosswalk_records << crosswalk_record
          rcc_log.debug "Client Level Record ID : #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
          if !facility.details[:cas_for_all_multiple_reason_codes_in_adjustment_field]
            break
          end
        end
      end
    end
    selected_crosswalk_records = client_level_crosswalk_records if client_level_crosswalk_records.present?
    if selected_crosswalk_records.blank? &&
        (facility.present? ? facility.details[:global_mapping] : true)
      rcc_log.debug "Obtaining Global Level Record"
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.active && crosswalk_record.crosswalk_active_indicator == 1 &&
            crosswalk_record.hipaa_code_id.present? && crosswalk_record.facility_id.blank? && crosswalk_record.client_id.blank?
          global_level_crosswalk_records << crosswalk_record
          rcc_log.debug "Global Level Record ID : #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
          if !facility.details[:cas_for_all_multiple_reason_codes_in_adjustment_field]
            break
          end
        end
      end
    end
    selected_crosswalk_records = global_level_crosswalk_records if global_level_crosswalk_records.present?

    if crosswalk_records.present?
      primary_crosswalk_record = selected_crosswalk_records.first
      if facility.details[:cas_for_all_multiple_reason_codes_in_adjustment_field]
        selected_crosswalk_records.delete_at(0)
      end
    end
    rcc_log.debug "Primary Crosswalk Record  : #{primary_crosswalk_record.crosswalk_record_id if primary_crosswalk_record}"
    rcc_log.debug "Secondary Crosswalk Records  : #{selected_crosswalk_records.map(&:crosswalk_record_id) if selected_crosswalk_records}"
    return primary_crosswalk_record, selected_crosswalk_records
  end

  # A predicate method for checking if a reason code is crosswalked or not. (Not used in the application)
  def is_reason_code_crosswalked?(reason_code_object)
    if reason_code_object.present?
      crosswalk_record_exists = does_site_level_crosswalk_exist(reason_code_object)
      if !crosswalk_record_exists
        crosswalk_record_exists = does_client_level_crosswalk_exist(reason_code_object)
      end
      if !crosswalk_record_exists
        crosswalk_record_exists = does_global_level_crosswalk_exist(reason_code_object)
      end
    end
  end

  # Obtains the crosswalk record for a reason code as an object of ReasonCode based on site / client / global level hierarchy
  # Input :
  # reason_code_object : An object of ReasonCode
  # Output :
  # crosswalk_record : crosswalk record as an object of ReasonCode based on site / client / global level hierarchy
  def get_crosswalk_record_for_a_reason_code(reason_code_object)
    if reason_code_object.present?
      crosswalk_records = get_reason_code_and_crosswalk_records([reason_code_object.id])
      crosswalk_record, secondary_crosswalk_record = get_crosswalk_record_for_reason_codes(crosswalk_records)
    end
    crosswalk_record
  end

  # Obtains the crosswalk record based on the mapping code factor / CAS 02 configuration.(Not used in the application)
  # Input :
  # crosswalk_records : Collection of crosswalk_records as an object of ReasonCode
  # Output :
  # crosswalk_record : crosswalk record
  def get_crosswalk_record_having_mapping_code_factor(crosswalk_records)
    rcc_log.debug "Obtains the crosswalk record based on the mapping code factor : #{mapping_code_factor}"
    crosswalk_record_having_mapping_code_factor = nil
    if crosswalk_records.present?
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.present?
          if mapping_code_factor == 'HIPAA CODE'
            crosswalked_code = hipaa_code_related_to_partner_and_payment_condition(crosswalk_record)
          elsif @is_partner_bac && mapping_code_factor == 'CLIENT CODE'
            crosswalked_code = client_code_related_to_partner_and_payment_condition(crosswalk_record)
          end
          if crosswalked_code.present?
            crosswalk_record_having_mapping_code_factor = crosswalk_record
            break
          end
        end
      end
    end
    rcc_log.debug "The chosen crosswalked record having the mapping_code_factor, \
    #{mapping_code_factor} is #{crosswalk_record_having_mapping_code_factor.id if crosswalk_record_having_mapping_code_factor.present?}"
    crosswalk_record_having_mapping_code_factor
  end

  # Obtain the hash of crosswalked codes for different usecases
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes for different usecases
  def build_crosswalked_codes(crosswalk_record = nil, hipaa_codes_from_entity = nil, secondary_crosswalk_records = nil)
    crosswalked_codes = {}
    if hipaa_codes_from_entity.present?
      crosswalked_codes[:hipaa_codes_from_entity] = true
      crosswalked_codes[:hipaa_code] = hipaa_code(nil, hipaa_codes_from_entity)
      crosswalked_codes[:hipaa_code_from_entity] = hipaa_codes_from_entity
    else
      crosswalked_codes[:all_reason_codes] = get_all_reason_codes_and_descriptions
      crosswalked_codes[:reason_codes_and_descriptions] = reason_codes_and_descriptions      
      crosswalked_codes[:reason_code_description] = normalized_reason_code_description(crosswalk_record)
    end
    if not @code_norc_found
      crosswalked_codes[:default_group_code] = default_group_code
      crosswalked_codes[:group_code] = group_code(crosswalk_record, crosswalked_codes)
      crosswalked_codes[:default_code] = default_code
      crosswalked_codes[:remark_codes] = normalized_remark_codes(crosswalk_record)
      if hipaa_codes_from_entity.present? || crosswalk_record.present?
        crosswalked_codes[:is_crosswalked] = true
      end
      if hipaa_codes_from_entity.blank? && crosswalk_record.present?
        crosswalked_codes[:is_reason_code_crosswalked] = true
        crosswalked_codes[:primary_reason_code_id] = primary_reason_code_id(crosswalk_record)
        crosswalked_codes[:hipaa_code] = hipaa_code_related_to_partner_and_payment_condition(crosswalk_record)
        crosswalked_codes[:secondary_codes] = get_all_secondary_codes(secondary_crosswalk_records, crosswalked_codes)
        crosswalked_codes[:reason_code] = normalized_reason_code(crosswalk_record)        
        crosswalked_codes[:original_reason_code] = original_reason_code(crosswalk_record)
        crosswalked_codes[:unique_code] = unique_code(crosswalk_record)
        if @is_partner_bac
          crosswalked_codes[:client_code] = client_code_related_to_partner_and_payment_condition(crosswalk_record) if @is_partner_bac
          crosswalked_codes[:claim_status_code] = crosswalk_record.claim_status_code
          crosswalked_codes[:denied_claim_status_code] = crosswalk_record.denied_claim_status_code
          crosswalked_codes[:reporting_activity1] = crosswalk_record.reporting_activity1
          crosswalked_codes[:reporting_activity2] = crosswalk_record.reporting_activity2
        end
      end
      crosswalked_codes[:cas_01] = get_cas01_code(crosswalked_codes)
      crosswalked_codes[:cas_02] = get_cas02_code(crosswalked_codes)
      crosswalked_codes[:secondary_cas_01] = get_secondary_cas01_code(crosswalked_codes)
      crosswalked_codes[:secondary_cas_02] = get_secondary_cas02_code(crosswalked_codes)
    end
    crosswalked_codes
  end

  # Obtain the hash of crosswalked codes relevant for a reason code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes
  def build_crosswalked_codes_for_a_reason_code(crosswalk_record)
    crosswalked_codes = {}
    crosswalked_codes[:reason_code] = reason_code
    crosswalked_codes[:unique_code] = unique_code
    crosswalked_codes[:footnote_code] = footnote_code(reason_code_object)
    crosswalked_codes[:reason_code_description] = normalized_reason_code_description(crosswalk_record)
    crosswalked_codes[:remark_codes] = normalized_remark_codes(crosswalk_record)
    crosswalked_codes[:default_group_code] = default_group_code
    if crosswalk_record.present?
      crosswalked_codes[:hipaa_code] = hipaa_code(crosswalk_record)
      crosswalked_codes[:hipaa_code_active_indicator] = hipaa_code_active_indicator(crosswalk_record)
      crosswalked_codes[:crosswalk_record_active_indicator] = crosswalk_record.crosswalk_active_indicator
      if @is_partner_bac
        crosswalked_codes[:denied_hipaa_code] = denied_hipaa_code(crosswalk_record)
        crosswalked_codes[:denied_hipaa_code_active_indicator] = denied_hipaa_code_active_indicator
        crosswalked_codes[:client_code] = client_code(crosswalk_record)
        crosswalked_codes[:denied_client_code] = denied_client_code(crosswalk_record)
        crosswalked_codes[:claim_status_code] = crosswalk_record.claim_status_code
        crosswalked_codes[:denied_claim_status_code] = crosswalk_record.denied_claim_status_code
        crosswalked_codes[:reporting_activity1] = crosswalk_record.reporting_activity1
        crosswalked_codes[:reporting_activity2] = crosswalk_record.reporting_activity2
      end
    end
    crosswalked_codes
  end

  # Obtains the HIPAA Code related to partner and payment condition
  # For BAC and if it is zero payment then Denied HIPAA Code needs to be fetched, else HIPAA Code.
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # @hipaa_code : HIPAA Adjustment Code
  def hipaa_code_related_to_partner_and_payment_condition(crosswalk_record)
    if crosswalk_record
      if @zero_payment && is_partner_bac
        if crosswalk_record.denied_hipaa_code_id.present? && crosswalk_record.crosswalk_record_id.present?
          rc_crosswalk = ReasonCodesClientsFacilitiesSetName.find(crosswalk_record.crosswalk_record_id)
          if rc_crosswalk.present?
            @denied_hipaa_code_record = rc_crosswalk.denied_hipaa_code
            @hipaa_code = @denied_hipaa_code_record.hipaa_adjustment_code if @denied_hipaa_code_record
          end
        end
      else
        rcc_log.debug "Obtaining HIPAA CODE."
        if crosswalk_record.hipaa_code_active_indicator
          @hipaa_code = crosswalk_record.hipaa_adjustment_code
        elsif crosswalk_record.crosswalk_record_id.present?
          rcc_log.debug "hipaa_code_active_indicator is false. Obtaining the hipaa_record"
          rc_crosswalk = ReasonCodesClientsFacilitiesSetName.find(crosswalk_record.crosswalk_record_id)
          if rc_crosswalk.present?
            @hipaa_code_record = rc_crosswalk.hipaa_code
            if @hipaa_code_record && @hipaa_code_record.eligible_for_output?(get_eob)
              @hipaa_code = @hipaa_code_record.hipaa_adjustment_code if @hipaa_code_record.present?
            end
          end
        end
      end
    end
    rcc_log.debug "HIPAA CODE : #{@hipaa_code}"
    @hipaa_code.to_s.upcase
  end

  # Obtains the HIPAA Code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # hipaa_code : HIPAA Adjustment Code
  def hipaa_code(crosswalk_record = nil, hipaa_code_from_entity = nil)
    rcc_log.debug "Obtaining HIPAA CODE."
    hipaa_code = hipaa_code_from_entity
    if hipaa_code.blank? && crosswalk_record.present?
      hipaa_code = crosswalk_record.hipaa_adjustment_code
      rcc_log.debug "HIPAA CODE : #{hipaa_code}"
    end
    hipaa_code.to_s.upcase
  end

  # Obtains the Denied HIPAA Code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # denied_hipaa_code : Denied HIPAA Adjustment Code
  def denied_hipaa_code(crosswalk_record)
    rcc_log.debug "Obtaining Denied HIPAA CODE for zero payment."
    if crosswalk_record.denied_hipaa_code_id.present? && crosswalk_record.crosswalk_record_id.present?
      if @denied_hipaa_code_record.blank?
        rc_crosswalk = ReasonCodesClientsFacilitiesSetName.find(crosswalk_record.crosswalk_record_id)
        if rc_crosswalk.present?
          @denied_hipaa_code_record = rc_crosswalk.denied_hipaa_code
        end
      end
      denied_hipaa_code = @denied_hipaa_code_record.hipaa_adjustment_code if @denied_hipaa_code_record
    end
    rcc_log.debug "Denied HIPAA CODE : #{denied_hipaa_code}"
    denied_hipaa_code.to_s.upcase
  end

  # Obtains the HIPAA Active Indicator
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # active_indicator : HIPAA Active Indicator
  def hipaa_code_active_indicator(crosswalk_record)
    rcc_log.debug "Obtaining HIPAA code active indicator."
    rcc_log.debug "HIPAA Code Active Indicator: #{crosswalk_record.hipaa_code_active_indicator}"
    crosswalk_record.hipaa_code_active_indicator
  end

  # Obtains the Denied HIPAA Active Indicator
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # active_indicator : Denied HIPAA Active Indicator
  def denied_hipaa_code_active_indicator
    rcc_log.debug "Obtaining HIPAA code active indicator."
    if @denied_hipaa_code_record.present?
      rcc_log.debug "HIPAA Code Active Indicator: #{@denied_hipaa_code_record.active_indicator}, having ID : #{@denied_hipaa_code_record.id}"
      @denied_hipaa_code_record.active_indicator
    end
  end

  # Obtains the Client code related to partner and payment condition
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # client_code : Client code if not a zero payment else Denied Client Code
  def client_code_related_to_partner_and_payment_condition(crosswalk_record)
    if @zero_payment
      denied_client_code(crosswalk_record)
    else
      client_code(crosswalk_record)
    end
  end

  # Obtains the Client code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # client_code : Client code
  def client_code(crosswalk_record)
    rcc_log.debug "Obtaining CLIENT CODE."
    if crosswalk_record && crosswalk_record.crosswalk_record_id.present?
      crosswalk_record = ReasonCodesClientsFacilitiesSetName.find(crosswalk_record.crosswalk_record_id)
      if crosswalk_record.present?
        client_code_association_records = crosswalk_record.reason_codes_clients_facilities_set_names_client_codes.
          select{|rcfsc| rcfsc.category != 'DENIED' or rcfsc.category == nil}
        client_code_record = client_code_association_records.first.client_code if client_code_association_records.present?
        if client_code_record.present?
          client_code = client_code_record.adjustment_code
          rcc_log.debug "CLIENT CODE : #{client_code}, having ID : #{client_code_record.id}"
        end
      end
    end
    client_code.to_s.upcase
  end

  # Obtains the Denied Client code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # client_code : Denied Client code
  def denied_client_code(crosswalk_record)
    rcc_log.debug "Obtaining Denied CLIENT CODE for zero payment."
    if crosswalk_record && crosswalk_record.crosswalk_record_id.present?
      crosswalk_record = ReasonCodesClientsFacilitiesSetName.find(crosswalk_record.crosswalk_record_id)
      if crosswalk_record.present?
        client_code_association_records = crosswalk_record.reason_codes_clients_facilities_set_names_client_codes.
          select{|rcfsc| rcfsc.category == 'DENIED'}
        client_code_record = client_code_association_records.first.client_code if client_code_association_records.present?
        if client_code_record.present?
          denied_client_code = client_code_record.adjustment_code
          rcc_log.debug "Denied CLIENT CODE : #{denied_client_code}, having ID : #{client_code_record.id}"
        end
      end
    end
    denied_client_code.to_s.upcase
  end

  # Obtains the Reason Code or Its Footnote Code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # reason_code : Reason Code
  def normalized_reason_code(crosswalk_record = nil)
    reason_code_record = crosswalk_record.present? ? crosswalk_record : reason_code_object
    if reason_code_record.present?
      rcc_log.debug "Obtaining Reason Code having ID : #{reason_code_record.id} "
      if @fetch_footnote_code
        reason_code = footnote_code(reason_code_record)
      else
        reason_code = reason_code_record.reason_code
      end
    end
    rcc_log.debug "Reason Code : #{reason_code}"
    reason_code.to_s.upcase
  end
  
  def unique_code(crosswalk_record = nil)
    reason_code_record = crosswalk_record.present? ? crosswalk_record : reason_code_object
    if reason_code_record.present?
      rcc_log.debug "Obtaining Reason Code having ID : #{reason_code_record.id} "
      unique_code = footnote_code(reason_code_record)
    end
    rcc_log.debug "Unique Code : #{unique_code}"
    unique_code.to_s.upcase
  end

  def original_reason_code(crosswalk_record = nil)
    reason_code_record = crosswalk_record.present? ? crosswalk_record : reason_code_object
    if reason_code_record.present?
      rcc_log.debug "Obtaining Reason Code having ID : #{reason_code_record.id} "
      reason_code = reason_code_record.reason_code
    end
    rcc_log.debug "Reason Code : #{reason_code}"
    reason_code.to_s.upcase
  end

  def primary_reason_code_id(crosswalk_record = nil)
    reason_code_record = crosswalk_record.present? ? crosswalk_record : reason_code_object
    if reason_code_record.present?
      rcc_log.debug "Obtaining Reason Code having ID : #{reason_code_record.id} "
      reason_code_id = reason_code_record.id
    end
    rcc_log.debug "Primary Reason Code ID : #{reason_code_id}"
    reason_code_id
  end

  # Obtains the Reason Code
  # Output :
  # reason_code : Reason Code
  def reason_code
    if reason_code_object.present?
      rcc_log.debug "Obtaining Reason Code having ID : #{reason_code_object.id} "
      reason_code = reason_code_object.reason_code
      rcc_log.debug "Reason Code : #{reason_code}"
    end
    reason_code.to_s.upcase
  end

  # Obtains the Footnote Code
  # Input :
  # reason_code_obj : An object of ReasonCode
  # Output :
  # reason_code : Footnote Code
  def footnote_code(reason_code_obj)
    rcc_log.debug "Obtaining Footnote Code."
    if reason_code_obj.present?
      if @client && @client.name.upcase == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
        if reason_code_obj.reason_code.to_s.upcase != 'NORC'
          reason_code = reason_code_obj.normalized_unique_code_for_upmc
        end
      else
        reason_code = reason_code_obj.normalized_unique_code
      end
    end
    rcc_log.debug "Footnote Code : #{reason_code}"
    reason_code.to_s.upcase
  end

  # Obtains the Reason Code description
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # reason_code_description : Reason Code description
  def normalized_reason_code_description(crosswalk_record = nil)
    reason_code_record = crosswalk_record || reason_code_object
    if reason_code_record.present?
      rcc_log.debug "Obtaining Reason Code description having ID : #{reason_code_record.id} "
      reason_code_description = reason_code_record.reason_code_description
    end
    rcc_log.debug "Reason Code Description : #{reason_code_description}"
    reason_code_description.to_s.upcase
  end

  # Obtains all the Reason Codes and its descriptions (primary and secondary) of an adjustment reason in an array
  # to print in 835 LQ*HE Segment and its similar segments in XML
  # Output :
  # rc_and_desc : Array of Reason Code and its descriptions
  def get_all_reason_codes_and_descriptions
    rc_and_desc = []
    if @crosswalk_records && @crosswalk_records.length > 0
      rcc_log.debug "Obtaining All Reason codes and descriptions for Output Segments and tags."
      @crosswalk_records.each do |reason_code_record|
        if reason_code_record.present?
          code = reason_code_record.reason_code.to_s.upcase
          if @facility.details[:rc_crosswalk_done_by_client] && code == 'NORC'
            @code_norc_found = true
          end
          is_hipaa_crosswalk_present = reason_code_record.hipaa_code_active_indicator && reason_code_record.hipaa_adjustment_code.present?
          if (@facility.details[:rc_crosswalk_done_by_client].blank? ||
                (@facility.details[:rc_crosswalk_done_by_client] &&
                  !is_hipaa_crosswalk_present && code != 'NORC'))
            if @fetch_footnote_code
              reason_code = footnote_code(reason_code_record)
            else
              reason_code = reason_code_record.reason_code
            end
            reason_code_description = reason_code_record.reason_code_description.to_s.upcase
            reason_code = reason_code.to_s.upcase
            notify = reason_code_record.notify
            if reason_code.present? && reason_code_description.present?
              rc_and_desc << [reason_code, reason_code_description, notify, is_hipaa_crosswalk_present]
            end
          end
        end
      end
    end
    rc_and_desc = rc_and_desc.compact.uniq
    rcc_log.debug "Reason Codes and descriptions are : #{rc_and_desc.join(', ')}"
    rc_and_desc
  end

  # Obtains all the Reason Codes and its descriptions (primary and secondary) of an adjustment reason in an array
  # Output :
  # rc_and_desc : Array of Reason Code and its descriptions
  def reason_codes_and_descriptions
    rc_and_desc = []
    reason_code_record = nil
    if @crosswalk_records && @crosswalk_records.length > 0
      rcc_log.debug "Obtaining All Reason codes and descriptions."
      @crosswalk_records.each do |reason_code_record|
        if reason_code_record.present?
          reason_code = reason_code_record.reason_code
          reason_code_description = reason_code_record.reason_code_description.to_s.upcase
          reason_code = reason_code.to_s.upcase
          if reason_code.present? && reason_code_description.present?
            rc_and_desc << [reason_code, reason_code_description]
          end
        end
      end
    end
    rc_and_desc = rc_and_desc.compact.uniq
    rcc_log.debug "Reason Codes and descriptions are : #{rc_and_desc.join(', ')}"
    rc_and_desc
  end

  # Obtains the Group Code based on business logic
  # Output :
  # group_code : Group Code of Reason Code
  def group_code(crosswalk_record = nil, crosswalked_codes_hash = {})
    if facility
      client_group_code = client.group_code.to_s.strip.upcase
      if client_group_code == 'MDR' && (entity.class == ServicePaymentEob || entity.class == InsurancePaymentEob) && adjustment_reason == 'contractual'
        coinsurance = entity.class == ServicePaymentEob ? entity.amount('service_co_insurance') : entity.amount('total_co_insurance')
        payment = entity.class == ServicePaymentEob ?  entity.amount('service_paid_amount') : entity.amount('total_amount_paid_for_claim')
        ppp = entity.class == ServicePaymentEob ? entity.amount('primary_payment') : entity.amount('total_primary_payer_amount')
        if coinsurance.zero? && payment.zero? && ppp.zero?
          'OA'
        elsif !ppp.zero?
          'PI'
        else
          'CO'
        end
      else
        @default_mapping ||= @default_mappings[adjustment_reason.to_sym]        
        rcc_log.debug "Obtaining Group Code."
        if facility.details[:apply_group_code_in_crosswalk] && 
            facility.enable_crosswalk.present? && @default_mapping && @default_mapping.enable_crosswalk
          if crosswalk_record &&  crosswalk_record.attributes.include?("hipaa_group_code") && crosswalk_record.hipaa_group_code.present?
            group_code = crosswalk_record.hipaa_group_code
          end
        end
        if group_code.blank?          
          group_code = @default_mapping.group_code if @default_mapping.present?
        end
        if ['miscellaneous_one', 'miscellaneous_two'].include?(adjustment_reason) && crosswalked_codes_hash &&
            crosswalked_codes_hash[:hipaa_codes_from_entity]
          group_code = 'CO'
        end
        rcc_log.debug "Group Code : #{group_code}"
        group_code.to_s.upcase
      end
    end
  end

  def default_group_code
    if adjustment_reason.present?
      @default_mapping ||= @default_mappings[adjustment_reason.to_sym]
      group_code = @default_mapping.group_code if @default_mapping.present?
    end
    rcc_log.debug "Deafult Group Code : #{group_code}"
    group_code.to_s.upcase
  end

  # Obtains the Remark Codes
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # remark_codes : An array of Remark Code
  def normalized_remark_codes(crosswalk_record = nil)
    rcc_log.debug "Obtaining Remark Codes."
    remark_codes = []
    reason_code_record = crosswalk_record || reason_code_object
    if reason_code_record.present? && reason_code_record.remark_code_crosswalk_flag
      facility_crosswalk_codes, client_crosswalk_codes, global_crosswalk_codes = [], [], []
      rcc_log.debug "Reason Code Record ID : #{reason_code_record.id}"
      crosswalk_records = ReasonCodesAnsiRemarkCode.select("
        ansi_remark_codes.adjustment_code AS adjustment_code,
        reason_codes_ansi_remark_codes.facility_id AS facility_id,
        reason_codes_ansi_remark_codes.client_id AS client_id").
        joins("INNER JOIN ansi_remark_codes ON ansi_remark_codes.id = reason_codes_ansi_remark_codes.ansi_remark_code_id").
        where(:reason_code_id => reason_code_record.id,
        :active_indicator => true)

      if crosswalk_records && crosswalk_records.length > 0
        crosswalk_records.each do |record|
          if record.facility_id == facility.id
            facility_crosswalk_codes << record.adjustment_code
          elsif record.client_id == client.id && record.facility_id.blank?
            client_crosswalk_codes << record.adjustment_code
          elsif record.client_id.blank? && record.facility_id.blank?
            global_crosswalk_codes << record.adjustment_code
          end
        end

        if facility_crosswalk_codes.present?
          remark_codes = facility_crosswalk_codes
          rcc_log.debug "Facility Level Remark Code Crosswalk"
        end
        if remark_codes.blank?
          remark_codes = client_crosswalk_codes
          rcc_log.debug "Client Level Remark Code Crosswalk"
        end
        if remark_codes.blank?
          remark_codes = global_crosswalk_codes
          rcc_log.debug "Global Level Remark Code Crosswalk"
        end
      else
        rcc_log.debug "There are no Remark Code Crosswalk records"
      end
    end
    rcc_log.debug "Remark Code : #{remark_codes.join(', ')}"
    remark_codes
  end

  # Obtains the default code that needs to be given when there is no crosswalk record is found.
  # Output :
  # default_code : default code
  def default_code
    rcc_log.debug "Obtaining Default Codes."
    if facility
      default_code = facility.details[:default_cas_code]
      rcc_log.debug "Default CAS Code from FC : #{default_code}"
      if default_code.blank?
        @default_mapping ||= @default_mappings[adjustment_reason.to_sym]
        default_code = @default_mapping.hipaa_adjustment_code unless @default_mapping.blank?
        rcc_log.debug "Default HIPAA Code from FC : #{default_code}"
        if default_code.blank? && !(['miscellaneous_one', 'miscellaneous_two', 'pr', 'prepaid'].include?(adjustment_reason))
          p "Please configure the default codes for #{adjustment_reason} to continue."
          raise "Please configure the default codes for #{adjustment_reason} to continue."
        end
      end
      default_code.to_s.upcase
    end
  end

  # Obtains the CAS 01 code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # cas_01_code : CAS 01 code
  def get_cas01_code(crosswalked_codes)
    rcc_log.debug "Obtaining CAS 01 code."
    if facility && crosswalked_codes
      cas_01_config = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
      rcc_log.debug "CAS 01 config : #{facility.details[:cas_01]}"
      rcc_log.debug "Obtaining Group code as CAS 01 code."
      cas_01_code = crosswalked_codes[cas_01_config.to_sym]
      rcc_log.debug "CAS 01 code : #{cas_01_code}"
    end
    cas_01_code.to_s.upcase
  end

  # Obtains the CAS 02 code
  # Input :
  # crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  # Output :
  # cas_01_code : CAS 02 code
  def get_cas02_code(crosswalked_codes)
    rcc_log.debug "Obtaining CAS 02 code."
    if facility
      cas_02_config = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
      if facility.details[:rc_crosswalk_done_by_client]
        cas_02_config = 'hipaa_code'
      end
      rcc_log.debug "CAS 02 config : #{facility.details[:cas_02]}"
      if facility.enable_crosswalk.present? && cas_02_config.present? && crosswalked_codes
        cas_02_code = crosswalked_codes[cas_02_config.to_sym]
      end
      if(cas_02_code.blank?)
        rcc_log.debug "New Reason Code or Reason Code without a crosswalk condition or crosswalking is not enabled."
        if crosswalked_codes && (cas_02_config == 'hipaa_code' || cas_02_config == 'client_code')
          rcc_log.debug "Obtaining default code as CAS 02 code."
          cas_02_code = crosswalked_codes[:default_code]
        elsif cas_02_config == 'reason_code'
          rcc_log.debug "Obtaining reason code as CAS 02 code."
          cas_02_code, desc = get_reason_code_and_description(crosswalked_codes)
          if cas_02_code.blank? && crosswalked_codes
            cas_02_code = crosswalked_codes[:hipaa_code_from_entity] if crosswalked_codes[:hipaa_code_from_entity].present?
          end
        end
      end
      rcc_log.debug "CAS 02 code : #{cas_02_code}"
    end
    cas_02_code.to_s.upcase
  end

  def get_secondary_cas02_code(crosswalked_codes)
    if @facility.details[:cas_segments_for_adjustment_with_crosswalked_and_default_codes] &&
        !(['miscellaneous_one', 'miscellaneous_two'].include?(adjustment_reason))
      if crosswalked_codes[:is_crosswalked].present?
        secondary_cas02_code = crosswalked_codes[:default_code]
      end
      rcc_log.debug "Secondary CAS 02 code : #{secondary_cas02_code}"
    end
    secondary_cas02_code.to_s.upcase
  end

  def get_secondary_cas01_code(crosswalked_codes)
    if @facility.details[:cas_segments_for_adjustment_with_crosswalked_and_default_codes] &&
        !(['miscellaneous_one', 'miscellaneous_two'].include?(adjustment_reason))
      if crosswalked_codes[:is_crosswalked]
        secondary_cas01_code = crosswalked_codes[:default_group_code]
      end
      rcc_log.debug "Secondary CAS 02 code : #{secondary_cas01_code}"
    end
    secondary_cas01_code.to_s.upcase
  end

  # Obtains the InsurancePaymentEob / EOB object from the entity object.
  # The entity object can be an object of ServicePaymentEob or InsurancePaymentEob
  # entity : object of InsurancePaymentEob
  def get_eob
    if entity
      if entity.class == ServicePaymentEob
        entity.insurance_payment_eob
      else
        entity
      end
    end
  end

  # Provide crosswalked codes for all the adjustment reasons for an entity.
  # Please see the top of the file for more info with Eg.
  # Input :
  # entity : ServicePaymentEob.find(<id>) for service level EOBs
  # or
  # entity : InsurancePaymentEob.find(<id>) for claim level EOBs
  # is_crosswalked_codes_needed = false : Provides only primary_reason_codes, primary_reason_code_descriptions,
  # all_reason_codes, all_reason_code_descriptions in hash
  # is_crosswalked_codes_needed = true : Provides all the crosswalked codes in the hash
  # Output :
  # crosswalked_codes : A hash returning crosswalked codes for all the adjustment reasons for an entity
  # Each value element of the hash is an array of the unique respective codes as described by the key.
  def get_all_codes_for_entity(entity, is_crosswalked_codes_needed = nil)
    rcc_log.debug "Generating codes for the output files such as A36, HREOB, 835 for claim type in Quadax"
    rcc_log.debug "Obtaining all the codes for the entity : #{entity} having id : #{entity.id}"
    @entity = entity
    primary_reason_codes, primary_reason_code_descriptions = [], []
    all_reason_codes,  all_reason_code_descriptions = [], []
    hipaa_codes, client_codes = [], []
    group_codes = []
    remark_codes = []
    cas_01_codes, cas_02_codes = [], []
    claim_status_codes, denied_claim_status_codes = [], []
    reporting_activities_1, reporting_activities_2 = [], []
    crosswalked_codes = {}
    if @entity.present? && @payer.present? && @client.present? && @facility.present?
      associated_codes_for_adjustment_elements = adjustment_reason_elements
      associated_codes_for_adjustment_elements.each do |adjustment_reason|
        crosswalked_codes_for_adj_reason = get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
        if crosswalked_codes_for_adj_reason[:all_reason_codes].present?
          crosswalked_codes_for_adj_reason[:all_reason_codes].each do |rc_and_desc|
            if rc_and_desc.present?
              all_reason_codes << rc_and_desc[0] if rc_and_desc[0].present?
              all_reason_code_descriptions << rc_and_desc[1] if rc_and_desc[1].present?
            end
          end
        end
        if crosswalked_codes_for_adj_reason[:reason_code].present?
          primary_reason_codes << crosswalked_codes_for_adj_reason[:reason_code]
        else
          primary_reason_codes << all_reason_codes.first if all_reason_codes.present?
        end
        if crosswalked_codes_for_adj_reason[:reason_code_description].present?
          primary_reason_code_descriptions << crosswalked_codes_for_adj_reason[:reason_code_description]
        else
          primary_reason_code_descriptions << all_reason_code_descriptions.first if all_reason_code_descriptions.present?
        end
        if is_crosswalked_codes_needed.present?
          rcc_log.debug "Also obtaining the crosswalked codes other than
                      primary_reason_codes, primary_reason_code_descriptions,
                      all_reason_codes, all_reason_code_descriptions"
          hipaa_codes << crosswalked_codes_for_adj_reason[:hipaa_code] if crosswalked_codes_for_adj_reason[:hipaa_code].present?
          client_codes << crosswalked_codes_for_adj_reason[:client_code] if crosswalked_codes_for_adj_reason[:client_code].present?
          group_codes << crosswalked_codes_for_adj_reason[:group_code] if crosswalked_codes_for_adj_reason[:group_code].present?
          remark_codes << crosswalked_codes_for_adj_reason[:remark_codes] if crosswalked_codes_for_adj_reason[:remark_codes].present?
          cas_01_codes << crosswalked_codes_for_adj_reason[:cas_01] if crosswalked_codes_for_adj_reason[:cas_01].present?
          cas_02_codes << crosswalked_codes_for_adj_reason[:cas_02] if crosswalked_codes_for_adj_reason[:cas_02].present?
          claim_status_codes << crosswalked_codes_for_adj_reason[:claim_status_code] if crosswalked_codes_for_adj_reason[:claim_status_code].present?
          denied_claim_status_codes << crosswalked_codes_for_adj_reason[:denied_claim_status_code] if crosswalked_codes_for_adj_reason[:denied_claim_status_code].present?
          reporting_activities_1 << crosswalked_codes_for_adj_reason[:reporting_activity1] if crosswalked_codes_for_adj_reason[:reporting_activity1].present?
          reporting_activities_2 << crosswalked_codes_for_adj_reason[:reporting_activity2] if crosswalked_codes_for_adj_reason[:reporting_activity2].present?
        end
      end
      crosswalked_codes[:primary_reason_codes] = primary_reason_codes.compact.uniq
      crosswalked_codes[:primary_reason_code_descriptions] = primary_reason_code_descriptions.compact.uniq
      crosswalked_codes[:all_reason_codes] = all_reason_codes.compact.uniq
      crosswalked_codes[:all_reason_code_descriptions] = all_reason_code_descriptions.compact.uniq
      if is_crosswalked_codes_needed.present?
        crosswalked_codes[:hipaa_codes] = hipaa_codes.compact.uniq
        crosswalked_codes[:client_codes] = client_codes.compact.uniq
        crosswalked_codes[:group_codes] = group_codes.compact.uniq
        crosswalked_codes[:remark_codes] = remark_codes.flatten.compact.uniq
        crosswalked_codes[:cas_01_codes] = cas_01_codes.compact.uniq
        crosswalked_codes[:cas_02_codes] = cas_02_codes.compact.uniq
        crosswalked_codes[:claim_status_codes] = claim_status_codes.compact.uniq
        crosswalked_codes[:denied_claim_status_codes] = denied_claim_status_codes.compact.uniq
        crosswalked_codes[:reporting_activities_1] = reporting_activities_1.compact.uniq
        crosswalked_codes[:reporting_activities_2] = reporting_activities_2.compact.uniq
      end
      if crosswalked_codes.present?
        crosswalked_codes
      else
        rcc_log.debug "crosswalked codes hash is empty"
      end
    else
      rcc_log.error "Client or Facility or Payer or Entity(InsurancePaymentEob or ServicePaymentEob object) is missing."
    end
  end

  def get_all_codes(adjustment_reason)
    rcc_log.debug "Obtining all the codes related to reason code for Aggregate Report, Archival 835"
    array_of_hashes = []
    crosswalked_codes = get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
    reason_code_ids = @reason_code_ids_from_entity
    rcc_log.debug "All the reason code related codes for report are generated."
    rcc_log.debug "All reason_code_ids : #{reason_code_ids.join(',') if reason_code_ids}"
    if reason_code_ids.present?
      rcc_log.debug "crosswalked_codes[:primary_reason_code_id] : #{crosswalked_codes[:primary_reason_code_id]}"
      get_codes_from_primary_reason_code_records(adjustment_reason, reason_code_ids, crosswalked_codes, array_of_hashes)
      get_codes_from_secondary_reason_code_records(adjustment_reason, reason_code_ids, crosswalked_codes, array_of_hashes)
    end
    get_codes_from_hipaa_code_from_entity(adjustment_reason, crosswalked_codes, array_of_hashes)
    array_of_hashes = array_of_hashes.flatten.compact.uniq
    rcc_log.debug "array_of_hashes of all the codes"
    rcc_log.debug array_of_hashes
    array_of_hashes
  end

  private

  def get_codes_from_primary_reason_code_records(adjustment_reason, reason_code_ids, crosswalked_codes, array_of_hashes)
    rcc_log.debug "get_codes_from_primary_reason_code_records"
    reason_code_ids.each_with_index do |reason_code_id, index|
      if reason_code_id.to_i == crosswalked_codes[:primary_reason_code_id].to_i
        array_of_hashes[index] = prepare_hash_of_codes_related_to_reason_code(adjustment_reason, crosswalked_codes)
        break
      end
    end
    rcc_log.debug "array_of_hashes : #{array_of_hashes}"
    # Passed by reference
    array_of_hashes
  end

  def get_codes_from_secondary_reason_code_records(adjustment_reason, reason_code_ids_from_entity, crosswalked_codes, array_of_hashes)
    rcc_log.debug "get_codes_from_secondary_reason_code_records"
    reason_code_ids_from_entity.each_with_index do |reason_code_id, index|
      if crosswalked_codes[:secondary_codes]
        crosswalked_codes[:secondary_codes].each do |secondary_code_hash|
          rcc_log.debug "secondary_code_hash : #{secondary_code_hash}"
          if secondary_code_hash && secondary_code_hash[:reason_code_id].to_i == reason_code_id.to_i
            array_of_hashes[index] = prepare_hash_of_codes_related_to_reason_code(adjustment_reason, secondary_code_hash)
            break
          end
        end
      end
    end
    rcc_log.debug "array_of_hashes : #{array_of_hashes}"
    # Passed by reference
    array_of_hashes
  end

  def get_codes_from_hipaa_code_from_entity(adjustment_reason, crosswalked_codes, array_of_hashes)
    rcc_log.debug "get_codes_from_hipaa_code_from_entity, @hipaa_code_from_entity : #{@hipaa_code_from_entity}"
    if @hipaa_code_from_entity
      group_code = normalized_group_code(adjustment_reason, crosswalked_codes)
      if crosswalked_codes[:hipaa_codes_from_entity].present?
        array_of_hashes << {
          :hipaa_code => crosswalked_codes[:hipaa_code],
          :group_code => group_code,
          :cas_01 => crosswalked_codes[:cas_01],
          :cas_02 => crosswalked_codes[:cas_02]
        }
      end
    end
    rcc_log.debug "array_of_hashes : #{array_of_hashes}"
    # Passed by reference
    array_of_hashes
  end

  def prepare_hash_of_codes_related_to_reason_code(adjustment_reason, crosswalked_codes)
    group_code = normalized_group_code(adjustment_reason, crosswalked_codes)
    hipaa_code_of_primary_reason_code = crosswalked_codes[:hipaa_code].present? && crosswalked_codes[:hipaa_codes_from_entity].blank?
    {
      :reason_code => crosswalked_codes[:reason_code],
      :reason_code_description => crosswalked_codes[:reason_code_description],
      :unique_code => crosswalked_codes[:unique_code],
      :reason_code_id => crosswalked_codes[:primary_reason_code_id],
      :hipaa_code => crosswalked_codes[:hipaa_code],
      :is_reason_code_crosswalked => hipaa_code_of_primary_reason_code,
      :group_code => group_code,
      :remark_codes => crosswalked_codes[:remark_codes],
      :cas_01 => crosswalked_codes[:cas_01],
      :cas_02 => crosswalked_codes[:cas_02]
    }
  end

  def normalized_group_code(adjustment_reason, crosswalked_codes)
    group_code = crosswalked_codes[:group_code]
    if group_code.blank? && ['miscellaneous_one', 'miscellaneous_two'].include?(adjustment_reason)
      group_code = 'CO'
    end
    group_code
  end

  # Obtains the crosswalk record for a reason code at site / facility level
  # Input :
  # reason_code_object : reason code object
  # Output :
  # facility_level_crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  def crosswalk_record_for_a_reason_code_at_site_level(reason_code_object)
    facility_level_crosswalk_record = nil
    crosswalk_records = get_reason_code_and_crosswalk_records(reason_code_object.id)
    if crosswalk_records.present?
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.facility_id.present?
          rcc_log.debug "Obtaining Site Level Record"
          facility_level_crosswalk_record = crosswalk_record
          rcc_log.debug "Site Level Record ID: #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
          break
        end
      end
    end
    facility_level_crosswalk_record
  end

  # Obtains the crosswalk record for a reason code at client level
  # Input :
  # reason_code_object : reason code object
  # Output :
  # client_level_crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  def crosswalk_record_for_a_reason_code_at_client_level(reason_code_object)
    client_level_crosswalk_record = nil
    crosswalk_records = get_reason_code_and_crosswalk_records(reason_code_object.id)
    if crosswalk_records.present?
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.facility_id.blank? && crosswalk_record.client_id.present?
          client_level_crosswalk_record = crosswalk_record
          rcc_log.debug "Client Level Record ID : #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
          break
        end
      end
    end
    client_level_crosswalk_record
  end

  # Obtains the crosswalk record for a reason code at global level
  # Input :
  # reason_code_object : reason code object
  # Output :
  # global_level_crosswalk_record : An object of ReasonCode containing all the relevant and crosswalked codes
  def crosswalk_record_for_a_reason_code_at_global_level(reason_code_object)
    rcc_log.debug "Obtaining Global Level Record"
    global_level_crosswalk_record = nil
    crosswalk_records = get_reason_code_and_crosswalk_records(reason_code_object.id)
    if crosswalk_records.present?
      rcc_log.debug "Obtaining Global Level Record"
      crosswalk_records.each do |crosswalk_record|
        if crosswalk_record.facility_id.blank? && crosswalk_record.client_id.blank?
          global_level_crosswalk_record = crosswalk_record
          rcc_log.debug "Global Level Record ID : #{crosswalk_record.crosswalk_record_id if crosswalk_record}"
          break
        end
      end
    end
    global_level_crosswalk_record
  end

  # A predicate method for checking if a reason code is crosswalked on the site / facility level
  def does_site_level_crosswalk_exist(reason_code_object)
    crosswalk_records = reason_code_object.reason_codes_clients_facilities_set_names.
      select{|rcsn| rcsn.facility_id != nil}
    rcc_log.debug "Does site level crosswalk exist: #{crosswalk_records.present? && crosswalk_records.length > 0}"
    crosswalk_records.present? && crosswalk_records.length > 0
  end

  # A predicate method for checking if a reason code is crosswalked on the client
  def does_client_level_crosswalk_exist(reason_code_object)
    crosswalk_records = reason_code_object.reason_codes_clients_facilities_set_names.
      select{|rcsn| rcsn.client_id != nil}
    rcc_log.debug "Does client level crosswalk exist: #{crosswalk_records.present? && crosswalk_records.length > 0}"
    crosswalk_records.present? && crosswalk_records.length > 0
  end

  # A predicate method for checking if a reason code is crosswalked on the global level
  def does_global_level_crosswalk_exist(reason_code_object)
    crosswalk_records = reason_code_object.reason_codes_clients_facilities_set_names.
      select{|rcsn| rcsn.facility_id == nil && rcsn.client_id == nil}
    rcc_log.debug "Does global level crosswalk exist: #{crosswalk_records.present? && crosswalk_records.length > 0}"
    crosswalk_records.present? && crosswalk_records.length > 0
  end

  # Obtains crosswalked codes for adjustment reason having crosswalk disabled
  # Output :
  # crosswalked_codes : A hash containing all the relevant codes for a reason code belonging to an adjustment reason
  def get_codes_for_adjustment_reason_having_crosswalk_disabled
    @reason_code_object = @crosswalk_records.first
    build_codes_for_adjustment_reason_having_crosswalk_disabled
  end

  def get_all_secondary_codes(secondary_crosswalk_records = nil, crosswalked_codes = nil )
    rcc_log.debug "Obtaining all the secondary reason code related codes"
    secondary_code_array = []
    if facility.details[:multiple_reason_codes_in_adjustment_field] &&
        facility.details[:cas_for_all_multiple_reason_codes_in_adjustment_field]
      rcc_log.debug "Multiple reason codes are configured to obtain all the secondary reason code related codes"
      reason_code_ids = @reason_code_ids_from_entity
      rcc_log.debug "reason_code_ids : #{reason_code_ids}"
      rcc_log.debug "crosswalked_codes[:primary_reason_code_id] : #{crosswalked_codes[:primary_reason_code_id]}"
      secondary_reason_code_ids = []
      reason_code_ids.each do |value|
        if value.present? && value.to_i != crosswalked_codes[:primary_reason_code_id].to_i
          secondary_reason_code_ids << value
        end
      end
      rcc_log.debug "secondary_reason_code_ids : #{secondary_reason_code_ids}"
      if secondary_crosswalk_records.blank? && secondary_reason_code_ids.present?
        secondary_crosswalk_records  = ReasonCode.where(:id => secondary_reason_code_ids)
      end
      if secondary_crosswalk_records && secondary_crosswalk_records.length > 0 && secondary_reason_code_ids.present?
        rcc_log.debug "secondary_crosswalk_records : #{secondary_crosswalk_records.map(&:id)}"
        secondary_records = get_ordered_secondary_reason_code_records(secondary_crosswalk_records, secondary_reason_code_ids)
        if secondary_records.present?
          secondary_code_array = get_secondary_records_codes_hash(secondary_records)
          if secondary_code_array.present?
            secondary_code_array = get_secondary_codes_in_relation_to_crosswalk_config(secondary_code_array)
          end
        end
      end
    end
    rcc_log.debug "secondary_code_array of all the reason codes"
    rcc_log.debug secondary_code_array
    secondary_code_array
  end

  def get_ordered_secondary_reason_code_records(secondary_crosswalk_records, secondary_reason_code_ids)
    rcc_log.debug "get_ordered_secondary_reason_code_records"
    secondary_records = []
    secondary_records_hash = {}
    rc_ids_to_find = []
    secondary_crosswalk_records.each do |record|
      secondary_records_hash[record.id] = record
    end
    secondary_reason_code_ids.each do |rc_id|
      if secondary_records_hash[rc_id]
        secondary_records << secondary_records_hash[rc_id]
      else
        rc_ids_to_find << rc_id
        secondary_records << rc_id
      end
    end
    if rc_ids_to_find.present? && secondary_records.length > 0
      secondary_records = get_rc_records_and_place_it_in_ordered_hash(rc_ids_to_find, secondary_records)
    end
    rcc_log.debug "secondary_records"
    rcc_log.debug "secondary_records : #{secondary_records.map(&:id) if secondary_records}"
    secondary_records
  end

  def get_rc_records_and_place_it_in_ordered_hash(rc_ids_to_find, secondary_records)
    rcc_log.debug "get_rc_records_and_place_it_in_ordered_hash"
    rc_records = ReasonCode.where(:id => rc_ids_to_find)
    if rc_records.length > 0
      secondary_records_hash = {}
      rc_records.each do |record|
        secondary_records_hash[record.id] = record
      end
      if secondary_records.length > 0
        secondary_records.each_with_index do |secondary_record, index|
          if secondary_record && secondary_record.class != ReasonCode
            secondary_records[index] = secondary_records_hash[secondary_record]
          end
        end
      end
    end
    rcc_log.debug "secondary_records : #{secondary_records.map(&:id) if secondary_records}"
    secondary_records
  end

  def get_secondary_records_codes_hash(secondary_records)
    rcc_log.debug "get_secondary_records_codes_hash"
    secondary_code_array = []
    secondary_records.each do |record|
      @reason_code_object = record
      reason_code = normalized_reason_code
      description = normalized_reason_code_description
      if record.attributes.include?("hipaa_adjustment_code")
        crosswalked_code = hipaa_code_related_to_partner_and_payment_condition(record)
      end
      group_code = group_code(record) if crosswalked_code.present?
      secondary_code_array << {
        :reason_code => reason_code, :reason_code_description => description,
        :reason_code_id => record.id, :unique_code => unique_code,
        :group_code => group_code, :remark_codes => normalized_remark_codes(record),
        :hipaa_code => crosswalked_code, :is_reason_code_crosswalked =>  crosswalked_code.present?
      }
    end
    rcc_log.debug "secondary_code_array"
    rcc_log.debug secondary_code_array
    secondary_code_array
  end

  def get_secondary_codes_in_relation_to_crosswalk_config(secondary_code_array)
    codes = secondary_code_array
    codes = []
    secondary_code_array.each do |crosswalked_codes_hash|
      rcc_log.debug "crosswalked_codes_hash : #{crosswalked_codes_hash} "
      crosswalked_codes_hash[:cas_01] = get_cas01_code(crosswalked_codes_hash)
      crosswalked_codes_hash[:cas_02] = get_cas02_code(crosswalked_codes_hash)
      codes << crosswalked_codes_hash
    end
    rcc_log.debug "The secondary reason code related codes are : #{codes}"
    codes
  end

end
