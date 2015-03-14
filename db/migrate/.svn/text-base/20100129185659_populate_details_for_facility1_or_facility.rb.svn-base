class PopulateDetailsForFacility1OrFacility < ActiveRecord::Migration
  def up
    facility_name = Facility.find_by_name("Facility")
    if( ( !facility_name.nil? || !facility_name.blank? ) && (facility_name.details.nil? || facility_name.details.blank? ) )
      facility_name.details = nil
      facility_name.details ={}      
      facility_name.details[:hcra] = true
      facility_name.details[:drg_code] = true
      facility_name.details[:patient_type] = true
      facility_name.details[:revenue_code] = true
      facility_name.details[:payment_code] = true
      facility_name.details[:claim_type] = true
      facility_name.details[:reference_code] = false
      facility_name.details[:service_date_from] = false
      facility_name.details[:check_date] = true
      facility_name.details[:payee_name] = true
      facility_name.details[:cpt_mandatory] = false
      facility_name.details[:edit_claim_total] = false
      facility_name.details[:claim_level_dos] = false
      facility_name.details[:group_code] = false
      facility_name.details[:check_date] = true
      facility_name.details[:late_fee_charge] = false
      facility_name.details[:rx_code] = false
      facility_name.details[:deposit_service_date] = false
      facility_name.details[:expected_payment] = false   
      facility_name.save!
    end   
    
    facility1_name = Facility.find_by_name("Facility1")
    if( ( !facility1_name.nil? || !facility1_name.blank? ) && (facility1_name.details.nil? || facility1_name.details.blank? ) )
      facility1_name.details = nil
      facility1_name.details ={}
      facility1_name.details[:hcra] = true
      facility1_name.details[:drg_code] = true
      facility1_name.details[:patient_type] = true
      facility1_name.details[:revenue_code] = true
      facility1_name.details[:payment_code] = true
      facility1_name.details[:claim_type] = true
      facility1_name.details[:reference_code] = false
      facility1_name.details[:service_date_from] = false
      facility1_name.details[:check_date] = true
      facility1_name.details[:payee_name] = true
      facility1_name.details[:cpt_mandatory] = false
      facility1_name.details[:edit_claim_total] = false
      facility1_name.details[:claim_level_dos] = false
      facility1_name.details[:group_code] = false
      facility1_name.details[:check_date] = true
      facility1_name.details[:late_fee_charge] = false
      facility1_name.details[:rx_code] = false
      facility1_name.details[:deposit_service_date] = false
      facility1_name.details[:expected_payment] = false   
      facility1_name.save!
    end      
  end

  def down
  end
end
