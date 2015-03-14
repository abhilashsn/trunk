class PopulateDetailsForLibertyHealthCarePharmacy < ActiveRecord::Migration
  def up
    liberty = Facility.find_by_name("Liberty Healthcare Pharmacy")
    if( ( !liberty.nil? || !liberty.blank? ) && (liberty.details.nil? || liberty.details.blank? ) )
      liberty.details = nil
      liberty.details ={}      
      liberty.details[:payee_name] = true
      liberty.details[:group_code] = false
      liberty.details[:claim_level_dos] = false
      liberty.details[:type] = 'Pharma'
      liberty.details[:edit_claim_total] = false
      liberty.details[:check_date] = true
      liberty.details[:revenue_code] = false
      liberty.details[:reference_code] = true
      liberty.details[:payment_code] = false
      liberty.details[:service_date_from] = true
      liberty.details[:late_fee_charge] = false
      liberty.details[:rx_code] = true
      liberty.details[:deposit_service_date] = false
      liberty.details[:claim_type] = true
      liberty.details[:drg_code] = false
      liberty.details[:patient_type] = false
      liberty.details[:expected_payment] = true
      liberty.details[:hcra] = false    
      liberty.save!
    end
  end

  def down
  end
end
