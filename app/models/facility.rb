# == Schema Information
# Schema version: 69
#
# Table name: facilities
#
#  id        :integer(11)   not null, primary key
#  name      :string(255)   
#  client_id :integer(11)   
#  sitecode  :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Facility < ActiveRecord::Base
  include OutputFacility
  
  belongs_to :client
  has_many :config_settings
  has_many :aba_dda_lookups
  has_many :batches, :dependent => :destroy
  has_many :facility_lockbox_mappings
  has_many :claim_file_informations
  has_many :facilities_npi_and_tins
  has_many :facilities_codes
  validates_presence_of :name
  validates_uniqueness_of :name  
  validates_presence_of :lockbox_number
  validates_presence_of :abbr_name
  validates_presence_of :client
  validates_presence_of :sitecode
  validates_numericality_of :tat
  validates_presence_of :address_one
  validates_presence_of :city
  validates_presence_of :state
  validates_presence_of :zip_code
  validates_presence_of :batch_load_type
  validates_presence_of :default_service_date
  validates_uniqueness_of :sitecode ,:if => :is_partner_bac 


  has_one :facilities_payers_information
  has_many :facilities_users
  has_many :users, :through => :facilities_users
  has_many :error_popups, :dependent => :destroy
  has_many :facility_output_configs, :dependent => :destroy
  has_many :facility_cut_relationships
  has_many :inbound_file_informations
  has_many :payer_exclusions
  has_many :payers ,:through => :payer_exclusions
  has_details :default_cas_code ,
    :cas_01,
    :cas_02,
    :lq_he,
    :default_mapping => :boolean,
    :global_mapping => :boolean,
    :drg_code => :boolean,
    :hcra => :boolean,
    :patient_type => :boolean,
    :claim_type => :boolean,
    :revenue_code => :boolean,
    :payment_code => :boolean,
    :reference_code => :boolean,
    :group_code => :boolean,
    :late_fee_charge => :boolean,
    :service_date_from => :boolean,
    :service_date_to => :boolean,
    :check_date => :boolean,
    :payee_name => :boolean,
    :edit_claim_total => :boolean,
    :claim_level_dos => :boolean,
    :rx_code => :boolean,
    :expected_payment => :boolean,
    :hipaa_code => :boolean,
    :patient_account_number_hyphen_format => :boolean,
    :interest_in_service_line => :boolean,
    :ansi_remark_code => :boolean,
    :payer_specific_reason_code => :boolean,
    :denied => :boolean,
    :claim_level_eob => :boolean,
    :date_received_by_insurer => :boolean,
    :carrier_code => :boolean,
    :transaction_type => :boolean,
    :micr_line_info => :boolean,
    :reference_code_mandatory => :boolean,
    :claim_normalized_factor => :integer,
    :service_line_normalised_factor => :integer
  alias_attribute :tin, :facility_tin
  alias_attribute :npi, :facility_npi
  has_many :default_codes_for_adjustment_reasons
  has_many :balance_record_configs, :dependent => :destroy
  has_many :rejection_comments
  has_many :facilities_micr_informations

  has_many :upmc_facilities, :foreign_key => 'lockbox_id'
  has_many :facility_aliases, :foreign_key => 'facility_id'
  
  belongs_to :batch_upload_parser
  
  attr_accessor :payer_ids_to_exclude, :payer_ids_to_include

  before_save :apply_format
  before_update :exclude_payer
  
  scope :none, where('1 = 0')
  scope :provides_conditions_with_relation_to_facilities_users, lambda { |condition_string, condition_values|
    if !condition_string.blank? && !condition_values.blank?
      where("#{condition_string} ", "#{condition_values}")
    else
      where(true)
    end
  }
  
  def apply_format
    self.details[:is_transpose] = false if !$IS_PARTNER_BAC
    self.name = name.upcase
  end
  
  def is_partner_bac
    $IS_PARTNER_BAC
  end

  def payer_ids_to_exclude
    excluded_payers.collect(&:payid).uniq.join(',')
  end

  def payer_ids_to_include
    included_payers.collect(&:payid).uniq.join(',')
  end

  def presense_of_default_cpt_and_ref_if_balance_record_applicable
    if (details[:balance_record_applicable] && details[:cpt_or_revenue_code_mandatory])
      if not default_cpt_code && default_ref_number
        errors[:base] << "Default CPT Code and Default REF Number are mandatory when Balance Record is chosen"
      end
    end
  end

  def total_col_span(claim_level_eob, is_insurance_grid)
    if(claim_level_eob)
      if is_insurance_grid
        if details[:remark_code]
          col_span = 12
        else
          col_span = 13
        end
        if details[:payment_status_code]
          col_span -= 1
        end
      else
        col_span = 7
      end
    else
      col_span = (is_insurance_grid ? 15 : 10)
      col_span -= 4 if self.details[:hide_modifiers]
      col_span += 1 if self.details[:tooth_number] && is_insurance_grid
    end

    col_span -= 2 unless self.details[:service_date_from]
    col_span -= 1 unless self.details[:reference_code]
    col_span -= 1 unless self.details[:revenue_code]
    col_span -= 1 unless self.details[:remark_code]   
    col_span -= 1 if !self.details[:payment_status_code] && is_insurance_grid
    col_span -= 1 if !self.details[:line_item] && is_insurance_grid
    if (!self.details[:rx_code] && is_insurance_grid)
      col_span -= 1
    end
    if (!self.details[:bundled_procedure_code] && is_insurance_grid)
      col_span -= 1
    end
    col_span
  end
 
  def total_col_span_patpay(claim_level_eob, is_insurance_grid)
   
    if(claim_level_eob)
      col_span = (is_insurance_grid ? 11 : 7)
    else
      col_span = (is_insurance_grid ? 12 : 10)
    end
    if (!claim_level_eob && !is_insurance_grid )          
      col_span -= 2 unless self.details[:service_date_from]
      col_span -= 1 unless self.details[:reference_code]
      col_span -= 1 unless self.details[:revenue_code]
      if (!self.details[:rx_code] && is_insurance_grid)
        col_span -= 1
      end
      if (!self.details[:bundled_procedure_code] && is_insurance_grid)
        col_span -= 1
      end
      col_span -= 4 if self.details[:hide_modifiers]
    else
      col_span -= 2 unless self.details[:service_date_from]
      col_span -=1
      col_span -= 4 if self.details[:hide_modifiers]
    end 
    col_span
  end
  
  def reason_code_mapping_colspan
    if self.details[:hipaa_code] && self.details[:ansi_remark_code]
      col_span = 4
    else
      col_span = 3
    end
  end
  
  def to_s
    self.name
  end
  
  def before_create
    if !@payer_ids_to_exclude.blank?
      excluded_pay_ids = @payer_ids_to_exclude.to_s.split(',')
      excluded_payers = Payer.find(:all, :select => "id", :conditions => ["payid in (?)",excluded_pay_ids])
      excluded_payers.each do  |payer|
        if !PayerExclusion.find_by_facility_id_and_payer_id(id, payer.id)
          payer_exclusions << PayerExclusion.new(:payer_id => payer.id, :status => 'EXCLUDED')
        end
      end
    elsif !@payer_ids_to_include.blank?
      included_pay_ids = @payer_ids_to_include.to_s.split(',')
      included_payers = Payer.find(:all, :select => "id", :conditions => ["payid in (?)",included_pay_ids])
      included_payers.each do |payer|
        if !PayerExclusion.find_by_facility_id_and_payer_id(id, payer.id)
          payer_exclusions << PayerExclusion.new(:payer_id => payer.id, :status => 'INCLUDED')
        end
      end
    end
  end
    
  def exclude_payer
    PayerExclusion.delete(payer_exclusions)
    before_create
  end

  def included_payers
    Payer.find(payer_exclusions.find_all_by_status('INCLUDED').collect(&:payer_id))
  end

  def excluded_payers
    Payer.find(payer_exclusions.find_all_by_status('EXCLUDED').collect(&:payer_id))
  end

  #  The labels of non-$amounts are hidden for Claim Level EOBs
  def label_name(name)
    if self.details[:claim_level_eob]
      return ""
    else
      return name
    end
  end

  #  The labels of non-$amounts are hidden for Claim Level EOBs new
  def label_name_new(name,claim_level_eob)
    if claim_level_eob
      return ""
    else
      return name
    end
  end

  # This method provides the UI validation for the Patient Account Number based on the configurations set on the facility
  def account_number_validation
    validation = ""
    is_partner_bac = $IS_PARTNER_BAC
    is_facility_moxp = (name.upcase == "MOUNT NITTANY MEDICAL CENTER")
    #This should be the next validation after 'required'.
    #Validations based on 'Allow Special Characters in Patient Account Number ' is
    #checked or not in FC UI.
    if !is_facility_moxp && self.details[:patient_account_number_hyphen_format]
      unless is_partner_bac
        validation << " validate-alphanumeric-hyphen-period-forwardslash"
        validation << " validate-conecutive-special-characters-for-patient-account-number-nonbank"
        validation << " validate-limit-of-special-characters"
      else
        validation << " validate-patient_account_number"
      end
    else
      validation << " validate-alphanumeric"
    end
    #Validations applicable to all.
    validation << " validate-accountnumber" unless is_partner_bac
    #Validations specific to client or facility.
    validation << " validate-rumc_accountnumber" if name.upcase == "RICHMOND UNIVERSITY MEDICAL CENTER"
    validation << " validate-qudax-account-number"
    validation << " validate-moxp-account-number" if is_facility_moxp
    validation
  end

  # Returns true if Remark Code is configured to have in LQ*HE segment
  def industry_code_configured?
    lq_he_config = details[:lq_he]
    unless lq_he_config.blank?
      lq_he_config[0].to_s.upcase == "REMARK CODE"  || lq_he_config[0].to_s.upcase == "ANSI REMARK CODE" ||
        lq_he_config[1].to_s.upcase == "REMARK CODE" || lq_he_config[1].to_s.upcase == "ANSI REMARK CODE"
    else
      false
    end
  end

  def claim_number_validation
    "validate-patient_account_number"
  end

  # The method 'ouput_config' provide the Ouput Configuration for the facility
  # It gives the Ouput Configuration based on the Type of the EOB like Patient Pay or Insurance EOB.
  # For obtaining the Patient Pay EOB Type Config, the payer of the check has to be of PatPay
  # For obtaining the Insurance EOB Type Config, the payer of the check has to be other than that of PatPay
  # Input :
  # payer_type : Payer Type
  # Output :
  # output_config : Configuration for the check
  def output_config(payer_type)
    if payer_type == "PatPay"
      patient_eob_config = FacilityOutputConfig.patient_eob(id)
      output_config = patient_eob_config.first if patient_eob_config.any?
    else
      insurance_eob_config = FacilityOutputConfig.insurance_eob(id)
      output_config = insurance_eob_config.first if insurance_eob_config.any?
    end
    output_config
  end

  def qualified_to_have_patient_payer?
    !patient_payerid.blank? && (patient_pay_format == "Simplified Format" || patient_pay_format == "Nextgen Format")
  end

  def output_configuration type
    (facility_output_configs.where(:eob_type => type, :report_type => 'Output')).first
  end

  def output_tin
    tin.blank? ?  facilities_npi_and_tins.first.tin.to_s :  tin
  end

  def output_npi
    npi.blank? ?  facilities_npi_and_tins.first.npi.to_s :  npi
  end
  
  # Class method which will run using delayed jobs.
  # Updates facility_lockbox_mappings and claim_informations table for client PDS.
  # Invoking during facility update from FCUI.
  class << self
    def update_facility_mapped_details(facility_id, lockbox_number_frm_ui, lockbox_name_frm_ui, url, current_user)
      begin
        facility_lockbox_mapping_exists = FacilityLockboxMapping.find_by_facility_id(facility_id)
        create_or_update_facility_lockbox_mappings(facility_lockbox_mapping_exists, facility_id, lockbox_number_frm_ui, lockbox_name_frm_ui)
        facility_npi_and_tin = FacilitiesNpiAndTin.select("id, npi").where(["facility_id = ?", facility_id])
        claim_info_with_facility_associated = ClaimInformation.select("id, facility_id, active").
          where(["facility_id = ?", facility_id])
        remove_facility_association(claim_info_with_facility_associated)
        add_facility_association(facility_id, facility_npi_and_tin)
      rescue => e
        puts e.message
        puts e.backtrace
        error_params = {}
        error_params[:url] = url
      end
    end

    def create_or_update_facility_lockbox_mappings(facility_lockbox_mapping_exists, facility_id, lockbox_number_frm_ui, lockbox_name_frm_ui)
      if facility_lockbox_mapping_exists.blank?
        FacilityLockboxMapping.create(:facility_id => facility_id,
          :lockbox_number => lockbox_number_frm_ui,
          :lockbox_name => "#{lockbox_name_frm_ui}_LBX")
      else
        facility_lockbox_mapping_exists.update_attributes(:lockbox_number => lockbox_number_frm_ui,
          :lockbox_name => "#{lockbox_name_frm_ui}_LBX")
      end
    end

    def remove_facility_association(claim_info_with_facility_associated)
      unless claim_info_with_facility_associated.blank?
        claim_info_with_facility_associated.each do |claim_info|
          claim_info.update_attributes(:facility_id => "", :active => '0')
        end
      end
    end

    def add_facility_association(facility_id, facility_npi_and_tin)
      unless facility_npi_and_tin.blank?
        facility_npi_and_tin.each do |facility_npi|
          claim_information_with_npi = ClaimInformation.select("id, facility_id, active, billing_provider_npi").
            where(["billing_provider_npi = ?", facility_npi[:npi]])
          unless claim_information_with_npi.blank?
            claim_information_with_npi.each do |claim_npi|
              claim_npi.update_attributes(:facility_id => facility_id, :active => '1')
            end
          end
        end
      end
    end
  end

  def get_lqhe_configs
    lq_he_configs = details[:lq_he]
    lq_he_configs = [] if lq_he_configs.blank?
    normalized_lqhe_configs = []
    if details[:rc_crosswalk_done_by_client]
      lq_he_configs << 'Reason Code' unless lq_he_configs.include?('Reason Code')
    end
    if lq_he_configs.present?
      lq_he_configs.each do |element|
        normalized_lqhe_configs << element.to_s.downcase.gsub(' ', '_') if element.present?
      end
    end
    normalized_lqhe_configs
  end

end
