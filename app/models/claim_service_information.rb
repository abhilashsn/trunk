require 'OCR_Data'
include OCR_Data
class ClaimServiceInformation < ActiveRecord::Base
  establish_connection(ActiveRecord::Base.configurations["mpi_data_#{Rails.env}"])
  belongs_to :claim_information
  has_many :service_payment_eobs
  # DCAP_REFACTOR BEGIN
  #alias_attribute :new_name :old_name
  alias_attribute :date_of_service_from, :service_from_date
  alias_attribute :date_of_service_to, :service_to_date
  alias_attribute :service_quantity, :days_units
  alias_attribute :service_provider_control_number, :provider_control_number
  alias_attribute :service_procedure_code, :cpt_hcpcts
  alias_attribute :service_procedure_charge_amount, :charges
  alias_attribute :service_modifier1, :modifier1
  alias_attribute :service_modifier2, :modifier2
  alias_attribute :service_modifier3, :modifier3
  alias_attribute :service_no_covered, :non_covered_charge
  alias_attribute :service_cdt_qualifier, :product_or_service_id_qualifier
  # DCAP_REFACTOR END
  
  def self.get_more
  	ClaimServiceInformation.find :first \
  		, :select => "GROUP_CONCAT(service_from_date) as service_frm_date \
			, GROUP_CONCAT(cpt_hcpcts) as cpt_code \
			, GROUP_CONCAT(charges) as charge \
			, COUNT(claim_information_id) as csi_count \
			, SUM(charges) as total_charge" \
  		, :group => "claim_information_id"
  end
  
  def self.service_line(claimid)
    @service_lines = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{claimid}")
    @service_lines.each do |service_line|
      from_dt = service_line.date_of_service_from
      to_dt = service_line.date_of_service_to
      valid_from_date = !from_dt.blank? && from_dt != "0000-00-00"
      valid_to_date = !to_dt.blank? && to_dt != "0000-00-00"
      service_line.date_of_service_from = from_dt.to_date if valid_from_date
      service_line.date_of_service_to = to_dt.to_date if valid_to_date
    end
    @service_lines
  end
  
  def self.total_noncovered_amount(id)
    total_non_covered_amount = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}",:select => "sum(non_covered_charge) amount",:group => "claim_information_id")
    total_non_covered_amount.each do |total|
      @total_non_covered_amount = total.amount
    end
    if(@total_non_covered_amount.blank?)
      @total_non_covered_amount = 0.00
    end
    return sprintf("%.2f", @total_non_covered_amount) if @total_non_covered_amount
  end

  def self.multiple_noncovered_amount(final_condition)
    @total_non_covered_amount = 0.00
    @service_lines =ClaimServiceInformation.find(:all,:conditions => final_condition)
    @service_lines.each do |sline|
      @total_non_covered_amount += sline.non_covered_charge.to_f
    end
    if(@total_non_covered_amount.blank?)
      @total_non_covered_amount = 0.00
    end
    return sprintf("%.2f", @total_non_covered_amount) if @total_non_covered_amount
  end

	# USELESS
  def self.service_date(id)
    @servicedate = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}").map{ |f| f.service_from_date}
    return @servicedate
  end

	# USELESS
  def self.service_frm_date(id)
    @service_frm_date = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}").map{ |f| f.service_from_date}
    @service_frm_date_array = ""
    @service_frm_date.each do |service_frm_date|
      @service_frm_date_array << service_frm_date.to_s + ","
    end
    return @service_frm_date_array.chop
  end

	# USELESS
  def self.cpt_code(id)
    @cpt_code = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}").map{ |f| f.cpt_hcpcts}
    @cpt_code_array = ""
    @cpt_code.each do |cpt_code|
      @cpt_code_array << cpt_code.to_s + ","
    end
    return @cpt_code_array.chop
  end

	# USELESS
  def self.charge(id)
    @charge = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}").map{ |f| f.charges}
    @charge_array = ""
    @charge.each do |charge|
      @charge_array << charge.to_s + ","
    end
    return @charge_array.chop
  end
  
	# USELESS
  def self.total_charges_amount(id)
    total_charges_amount = ClaimServiceInformation.find(:all,:conditions => "claim_information_id = #{id}",:select => "sum(charges) amount",:group => "claim_information_id")
    total_charges_amount.each do |total|
      @total_charges_amount = total.amount
    end
    if(@total_charges_amount.blank?)
      @total_charges_amount = 0.00
    end
    return sprintf("%.2f", @total_charges_amount) if @total_charges_amount
  end
  
  #This method returns the hash of md5-hash and ids
  def self.get_the_claim_service_info_hash claim_id
    query = "SELECT id, MD5(CONCAT(charges ,cpt_hcpcts,service_from_date)) AS 'md5_hash', MD5(CONCAT(charges ,cpt_hcpcts)) AS 'md5_hash_without_dos' FROM claim_service_informations WHERE claim_information_id = #{claim_id} order by id desc"
    claim_service_lines = self.find_by_sql(query)
    clm_svc_line_hash = {}
    claim_service_lines.each do |svc|
      unless svc.md5_hash.nil?
        clm_svc_line_hash[svc.md5_hash + "," + svc.md5_hash_without_dos] = svc.id
      end
    end
    return clm_svc_line_hash
  end
  
  def self.multiple_charges_amount(final_condition)
    @total_charges_amount = 0.00
    @service_lines =ClaimServiceInformation.find(:all,:conditions => final_condition)
    @service_lines.each do |sline|
      @total_charges_amount += sline.charges.to_f
    end
    if(@total_charges_amount.blank?)
      @total_charges_amount = 0.00
    end
    return sprintf("%.2f", @total_charges_amount) if @total_charges_amount
  end

  def self.claim_service_data(acc_no,date,charge)
    claim_service = ClaimServiceInformation.find(:first,:conditions => "claim_informations.patient_account_number = '#{acc_no}' and claim_service_informations.service_from_date ='#{date}' and  claim_service_informations.charges = #{charge} ",:include =>:claim_information)
    return claim_service
  end
  def class_for_service(present)
   
    unless (present==false)
      class_sta = "imported"
    end
    return class_sta
  end

  
  def coordinates(column)
    nil
  end
  def page(column)
    nil
  end

  def style(column)
    if column == "service_procedure_charge_amount"
      # This aims at providing a confirmation box to Charges $amount fields( alias 'Fields') if it has amount >= $10,000.
      # Only Charges field is present in 837 data.
      # If the user does not confirm it, the background color of 'Fields' changes to red color(class 'normalized_uncertain'), else yellow color(class 'edited').
      # This provides the background red if the 'Fields' are populated from 837 and has amount >= $10,000 else white color.
      if self.send(column).to_f >= 10000.00
        "normalized_uncertain"
      else
        OCR_Data::Origins::BLANK
      end
    else
      OCR_Data::Origins::BLANK
    end
  end
  
  # Adjustment Line is a service line with no Service Dates, CPT code, Charges etc. The fields from Payment to PPP will be active.
  # For the Claim service line, such Adjustment Line does not exist
  def adjustment_line_is?
    false
  end

  def get_tooth_number
    tooth_code = self.tooth_code
    unless tooth_code.blank?
      tooth_number = ""
      tooth_number_array = []
      space_removed = tooth_code.gsub(/\s+/, "")
      space_removed.split(',').each do |tc|
        tooth_number_array = tooth_number_array.push(tc.split(':').first)
      end      
      tooth_number = tooth_number_array.delete_if {|c| c.empty? }.uniq.join(',') unless tooth_number_array.blank?
    end
    return tooth_number
  end
  
  # Returns if the given service line is an interest service line.
  # For the 837 service lines there will not be any interest service line.
  def interest_service_line?
    false
  end

  def get_remark_codes
    []
  end

end
