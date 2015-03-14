class PopulateFacilityDetailsToFacility < ActiveRecord::Migration
  def up
    begin
    facilities = Facility.all
    facilities.each do |facility|
    client_id = facility.client_id
    client_name = Client.find_by_id(client_id).name
    facility.details = nil
    facility.details ={}
    if client_name.upcase == "MEDASSETS"
      facility.details[:hcra] = true
      facility.details[:drg_code] = true
      facility.details[:patient_type] = true
      facility.details[:revenue_code] = true
      facility.details[:payment_code] = true
      facility.details[:claim_type] = true
      facility.details[:reference_code] = false
      facility.details[:service_date_from] = false
      facility.details[:check_date] = true
      facility.details[:payee_name] = true
      facility.details[:cpt_mandatory] = false
      facility.details[:edit_claim_total] = false
      facility.details[:claim_level_dos] = false
      facility.details[:group_code] = false
      facility.details[:check_date] = true
      facility.details[:late_fee_charge] = false
      facility.details[:rx_code] = false
      facility.details[:deposit_service_date] = false
      facility.details[:expected_payment] = false
    elsif client_name.upcase == "MEDISTREAMS"
      facility.details[:hcra] = false
      facility.details[:drg_code] = false
      facility.details[:patient_type] = false
      facility.details[:revenue_code] = false
      facility.details[:payment_code] = false
      facility.details[:claim_type] = true
      facility.details[:reference_code] = true
      facility.details[:service_date_from] = true
      facility.details[:check_date] = true
      facility.details[:payee_name] = true
      facility.details[:cpt_mandatory] = true
      facility.details[:edit_claim_total] = true
      facility.details[:claim_level_dos] = true
      facility.details[:group_code] = false
      facility.details[:check_date] = true
      facility.details[:late_fee_charge] = false
      facility.details[:rx_code] = false
      facility.details[:deposit_service_date] = false
      facility.details[:expected_payment] = false
    elsif client_name.upcase == "NAVICURE"
      facility.details[:hcra] = false
      facility.details[:drg_code] = false
      facility.details[:patient_type] = false
      facility.details[:revenue_code] = false
      facility.details[:payment_code] = false
      facility.details[:claim_type] = true
      facility.details[:reference_code] = false
      facility.details[:service_date_from] = true
      facility.details[:check_date] = true
      facility.details[:payee_name] = true
      facility.details[:cpt_mandatory] = true
      facility.details[:edit_claim_total] = true
      facility.details[:claim_level_dos] = true
      facility.details[:group_code] = false
      facility.details[:check_date] = true
      facility.details[:late_fee_charge] = false
      facility.details[:rx_code] = false
      facility.details[:deposit_service_date] = false
      facility.details[:expected_payment] = false      
    elsif client_name.upcase == "ANODYNE" || client_name.upcase == "AHN"
      facility.details[:hcra] = false
      facility.details[:drg_code] = false
      facility.details[:patient_type] = false
      facility.details[:revenue_code] = false
      facility.details[:payment_code] = false
      facility.details[:claim_type] = true
      facility.details[:reference_code] = false
      facility.details[:service_date_from] = true
      facility.details[:check_date] = true
      facility.details[:payee_name] = true
      facility.details[:cpt_mandatory] = false
      facility.details[:edit_claim_total] = false
      facility.details[:claim_level_dos] = false
      facility.details[:group_code] = false
      facility.details[:check_date] = true
      facility.details[:late_fee_charge] = false
      facility.details[:rx_code] = false
      facility.details[:deposit_service_date] = false
      facility.details[:expected_payment] = false      
    end
      facility.save(:validate => false)
    end 
    rescue
      puts "Error in populating the details column!!!"
    end
  end

  def down
  end
end
