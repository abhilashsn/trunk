require 'nokogiri'

class Transformer_837
  attr_reader :doc

  ITERATORS = {
              "I837"                                => "/Export",
              "ICLM"                                => "Product",
              "ICLM_ITM"                            => "ClaimItems/ClaimItem"
              }
              
  CLAIM =     {              
              "insured_id"                          => "@MedicalRecordNumber",
              "provider_ein"                        => "@FederalTaxID",
              "total_charges"                       => "@TotalCharges",
              "payer_name"                          => "Remark/@Line2",
              "payer_address"                       => "Remark/@Line3",
              "payer_location"                      => "Remark/@Line4",
              "patient_names"                       => "@PatientName",
              "patient_account_number"              => "@PatientControlNumber",
              "provider_npi"                        => "@NPI",
              "provider_last_name"                  => "Physicians/Physician[1]/@LastName",
              "provider_first_name"                 => "Physicians/Physician[1]/@FirstName",
              "subscriber_names"                    => "@SubscriberName",
              "claim_statement_period_start_date"   => "@StatementFromDate",
              "claim_statement_period_end_date"     => "@StatementToDate",
              "patient_identification_number"       => "@PatientID",
              "billing_provider_organization_name"  => "@PayToName"
              }

  CLAIM_ITMS ={              
              "charges"                             => "@TotalCharges",
              "cpt_hcpcts"                          => "@HCPCSRates_HIPPSCodes",
              "days_units"                          => "@UnitsOfService",
              "service_from_date"                   => "@ServiceDate",
              "service_to_date"                     => "@ServiceDate",
              "revenue_code"                        => "@RevenueCode",
              "quantity"                            => "@UnitsOfService"
              }

  def initialize(file)
    @doc=Nokogiri::XML(File.open(file))
    @log = Logger.new('837Transform.log')
  end

  def transform
    @log.info ">>Transformation Starts"
      @doc.xpath(ITERATORS["I837"]).each do |e|
        @log.info "Number of claims: #{e.xpath(ITERATORS['ICLM']).count()}"
        e.xpath(ITERATORS["ICLM"]).each do |clms|
          clm = process_claim(clms)
          ci = 0

          clms.xpath(ITERATORS["ICLM_ITM"]).each do |clmitms|
            clm_itms = process_claim_itms(clmitms)
            clm.claim_service_informations << clm_itms
            ci = ci + 1
          end # clmitms
          
          @log.info " .... Claim itmes: #{ci}"
          clm.save
        end #clms
      end # @doc
    
    @log.info ">>Transformation Ends"
  end

  private
  
  def process_claim clms
    clm = ClaimInformation.new
    CLAIM.each do |k,v| 
      case k
        when "patient_names"
          frame_patient_names(clm,clms.xpath(v).text)
        when "subscriber_names"
          frame_subscriber_names(clm,clms.xpath(v).text)
        when "payer_location"
          frame_payer_location(clm,clms.xpath(v).text)
        else
          clm[k] = clms.xpath(v).text 
        end
    end
    return clm
  end
 
  def process_claim_itms clmitms
    clm_items = ClaimServiceInformation.new
    CLAIM_ITMS.each { |k,v| clm_items[k] = clmitms.xpath(v).text }
    return clm_items
  end
  
  def frame_patient_names(rec, val)
    unless val.blank?
      tmp = val.split(",") 
      rec["patient_last_name"] = tmp[0].strip
      rec["patient_first_name"] = tmp[1].strip
    end
  end

  def frame_subscriber_names(rec, val)
    unless val.blank?
      tmp = val.split(",") 
      rec["subscriber_last_name"] = tmp[0].strip
      rec["subscriber_first_name"] = tmp[1].strip
    end
  end
  
  def frame_payer_location(rec, val)
    unless val.blank?
      rec["payer_city"], tmp = val.split(",")
      tmp = tmp.strip
      rec["payer_state"], rec["payer_zipcode"] = tmp.split(" ")
    end
  end

end #class

if ARGV.length > 0
  trnsf = Transformer_837.new(ARGV[0])
  trnsf.transform
else
  puts "ERROR::Unable to process without 837 input file!"
end
