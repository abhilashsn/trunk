require 'nokogiri'
require 'logger'

class Transformer_835
  attr_reader :doc, :log

  ITERATORS = {
              "BAT_GS"                                      => "//GS",
              "I835"                                        => "../TS_835",
              "IEOB"                                        => "GROUP_2/GROUP_3",
              "IEOB_ITM"                                    => "GROUP_4"
              }
              
  CLAIM =     {              
              "claim_type"                                  => "CLP/CLP02",
              "claim_number"                                => "CLP/CLP07",
              "claim_status_code"                           => "CLP/CLP02",
              "claim_indicator_code"                        => "CLP/CLP06",
              "claim_interest"                              => "AMT[AMT01='I']/AMT02",
              "claim_from_date"                             => "../../DTM[DTM01=232]/DTM02",
              "claim_to_date"                               => "../../DTM[DTM01=233]/DTM02",
              "claim_adjustment_group_code"                 => "CAS[1]/CAS01",
              "claim_adjustment_reason_code"                => "CAS[1]/CAS02",              
              "claim_adjustment_contractual_amount"         => "CAS[CAS01='CO']/CAS03",     
              "claim_contractual_reasoncode"                => "CAS[CAS01='CO']/CAS02",
              "claim_contractual_groupcode"                 => "CAS[CAS02=45 or CAS05=45 or CAS02=42 or CAS05=42 or CAS02=94 or CAS05=94 or CAS02=97 or CAS05=97]/CAS01",              
              "claim_coinsurance_reasoncode"                => "CAS[CAS01='PR']/CAS02",
              "claim_coinsurance_groupcode"                 => "CAS[CAS02=2]/CAS01",
              "claim_copay_reasoncode"                      => "CAS[CAS01='PR']/CAS02",
              "claim_copay_groupcode"                       => "CAS[CAS02=3]/CAS01",
              "claim_deductable_reasoncode"                 => "CAS[CAS01='PR']/CAS02",
              "claim_deductuble_groupcode"                  => "CAS[CAS02=1]/CAS01",
              "claim_adjustment_non_covered"                => "CAS[CAS01='CO']/CAS03",            
              "claim_noncovered_reasoncode"                 => "CAS[CAS01='CO']/CAS02",
              "claim_noncovered_groupcode"                  => "CAS[CAS02=96]/CAS01",
              "claim_adjustment_discount"                   => "CAS[CAS01='CO']/CAS03",            
              "claim_discount_reasoncode"                   => "CAS[CAS01='CO']/CAS02",
              "claim_discount_groupcode"                    => "CAS[CAS02=131]/CAS01",
              "claim_adjustment_co_insurance"               => "CAS[CAS01='PR']/CAS03",             
              "claim_adjustment_deductable"                 => "CAS[CAS01='PR']/CAS03",            
              "claim_adjustment_copay"                      => "CAS[CAS01='PR']/CAS03",                  
              "claim_adjustment_primary_pay_payment"        => "CAS[CAS01='OA']/CAS03",    
              "claim_primary_payment_reasoncode"            => "CAS[CAS01='OA']/CAS02",
              "claim_primary_payment_groupcode"             => "CAS[CAS02=23]/CAS01",
              "claim_denied_reasoncode"                     => "CAS[CAS01='OA']/CAS02",
              "claim_denied_groupcode"                      => "CAS[CAS02=18]/CAS01",
              "claim_adjustment_charges"                    => "CLP/CLP03",
              "claim_adjustment_payment"                    => "CLP/CLP04",
              "drg_code"                                    => "CLP/CLP11",
              "drg_weight"                                  => "CLP/CLP12",
              "plan_type"                                   => "SBR/SBR09",
              "insured_id"                                  => "NM1[NM101='IL']/NM109",
              "provider_ein"                                => "GROUP_4/GROUP_6/NM1[NM101=82]/../REF/REF02",
              "payer_name"                                  => "NM1[NM101='PR']/NM103",
              "payer_address"                               => "NM1[NM101='PR']/../N3/N301",
              "payer_city"                                  => "NM1[NM101='PR']/../N4/N401",
              "payer_state"                                 => "NM1[NM101='PR']/../N4/N402",
              "payer_zipcode"                               => "NM1[NM101='PR']/../N4/N403",
              "patient_suffix"                              => "NM1[NM101='QC']/NM107",
              "patient_last_name"                           => "NM1[NM101='QC']/NM103",
              "patient_first_name"                          => "NM1[NM101='QC']/NM104",
              "patient_middle_initial"                      => "NM1[NM101='QC']/NM105",
              "patient_account_number"                      => "CLP/CLP01",
              "patient_identification_code"                 => "NM1[NM101='QC']/NM109",
              "patient_identification_code_qualifier"       => "NM1[NM101='QC']/NM108",
              "provider_npi"                                => "NM1[NM101=82 and NM108 = 'XX']/NM109",
              "provider_tin"                                => "NM1[NM101=82 and NM108 = 'FI']/NM109",
              "provider_organisation"                       => "NM1[NM101=82]/NM103",
              "rendering_provider_last_name"                => "NM1[NM101=82]/NM103",
              "rendering_provider_first_name"               => "NM1[NM101=82]/NM104",
              "rendering_provider_middle_initial"           => "NM1[NM101=82]/NM105",
              "rendering_provider_suffix"                   => "NM1[NM101=82]/NM107",
              "rendering_provider_identification_number"    => "NM1[NM101=82]/NM109",
              "rendering_provider_code_qualifier"           => "NM1/NM101",
              "provider_adjustment_reason_code"             => "../../PLB/PLB03/PLB0301",
              "provider_adjustment_amount"                  => "../../PLB/PLB03/PLB0304",
              "subscriber_last_name"                        => "NM1[NM101='IL' or NM101='MI']/NM103",
              "subscriber_first_name"                       => "NM1[NM101='IL' or NM101='MI']/NM104",
              "subscriber_middle_initial"                   => "NM1[NM101='IL' or NM101='MI']/NM105",
              "subscriber_suffix"                           => "NM1[NM101='IL' or NM101='MI']/NM107",
              "subscriber_identification_code"              => "NM1[NM101='IL' or NM101='MI']/NM109",
              "subscriber_identification_code_qualifier"    => "NM1[NM101='IL' or NM101='MI']/NM108",
              "insurance_policy_number"                     => "REF[REF01='IG']/REF02",
              "units_of_service_being_adjusted"             => "CAS/CAS04",
              "date_check_mailed_by_insurer"                => "BPR/BPR16",
              "late_filing_charge"                          => "../../PLB[PLB03=50]/PLB04",  
              "facility_type_code"                          => "TS3/TS302",
              "transaction_reference_identification_number" => "REF/REF02",
              "billing_provider_organization_name"          => "NM1[NM101=85]/NM103"
              }

  CLAIM_ITMS =  {              
              "rx_number"                                   => "LQ[LQ01='RX']/LQ02",
              "denied"                                      => "CAS[CAS01='OA']/CAS03",
              "denied_code"                                 => "CAS[CAS01='OA']/CAS02",
              "denied_groupcode"                            => "CAS[CAS02=18]/CAS01",
              "primary_payment"                             => "CAS[CAS01='OA']/CAS03",
              "service_discount"                            => "CAS[CAS01='CO']/CAS03",
              "revenue_code"                                => "SVC/SVC04",
              "service_co_insurance"                        => "CAS[CAS01='PR']/CAS03",                                 
              "primary_payment_code"                        => "CAS[CAS01='OA']/CAS02", 
              "primary_payment_groupcode"                   => "CAS[CAS02=23]/CAS01",
              "discount_code"                               => "CAS[CAS01='CO']/CAS02", 
              "discount_groupcode"                          => "CAS[CAS02=131]/CAS01",
              "coinsurance_code"                            => "CAS[CAS01='PR']/CAS02",
              "coinsurance_groupcode"                       => "CAS[CAS02=2]/CAS01",
              "service_deductible"                          => "CAS[CAS01='PR']/CAS03",                                     
              "deductuble_code"                             => "CAS[CAS01='PR']/CAS02",
              "deductuble_groupcode"                        => "CAS[CAS02=1]/CAS01",
              "service_co_pay"                              => "CAS[CAS01='PR']/CAS03",                                         
              "copay_code"                                  => "CAS[CAS01='PR']/CAS02",
              "copay_groupcode"                             => "CAS[CAS02=3]/CAS01",
              "service_no_covered"                          => "CAS[CAS01='CO']/CAS03",            
              "noncovered_code"                             => "CAS[CAS01='CO']/CAS02",
              "noncovered_groupcode"                        => "CAS[CAS02=96]/CAS01",
              "contractual_amount"                          => "CAS[CAS01='CO']/CAS03",            
              "contractual_groupcode"                       => "CAS[CAS02=45]/CAS01",
              "contractual_code"                            => "CAS[CAS01='CO']/CAS02",
              "procedure_code_type"                         => "SVC/SVC01/SVC0101",
              "service_procedure_code"                      => "SVC/SVC01/SVC0102",
              "service_modifier1"                           => "SVC/SVC01/SVC0103",
              "service_modifier2"                           => "SVC/SVC01/SVC0104",
              "service_modifier3"                           => "SVC/SVC01/SVC0105",
              "service_modifier4"                           => "SVC/SVC01/SVC0106",
              "service_procedure_charge_amount"             => "SVC/SVC02",
              "service_paid_amount"                         => "SVC/SVC03",
              "service_quantity"                            => "SVC/SVC05",
              "date_of_service_from"                        => "DTM[DTM01=150 or DTM01=472]/DTM02",
              "date_of_service_to"                          => "DTM[DTM01=151 or DTM01=472]/DTM02",
              "service_claim_adjustment_group_code"         => "CAS[1]/CAS01",
              "service_amount_qualifier_code"               => "AMT/AMT01",
              "service_amount"                              => "AMT/AMT02",
              "service_code_list_qualifier"                 => "LQ[1]/LQ01",
              "service_industry_code"                       => "LQ[1]/LQ02",
              "service_provider_number"                     => "../../../PLB/PLB01",
              "service_claim_adjustment_reason_code"        => "CAS[1]/CAS02",             
              "service_units_of_service_being_adjusted"     => "SVC/SVC05",
              "service_provider_control_number"             => "REF/REF01",                
              "service_allowable"                           => "AMT[AMT01='B6']/AMT02",
              "service_provider_control_number"     => "REF/REF02"
              }
              
  CHK =       {
              "check_date"                                  => "BPR/BPR16",
              "check_number"                                => "TRN/TRN02",
              "payment_type"                                => "BPR/BPR04",
              "check_amount"                                => "BPR/BPR02",
              "provider_adjustment_amount"                  => "PLB/PLB04"
              }
              
  MICR =      {
              "aba_routing_number"                          => "BPR/BPR07",
              "payer_account_number"                        => "BPR/BPR09"
              }
              
  BATCH =     {"date"                                       => "GS04"}
  PAY =       {"payer"                                      => "GROUP_1/N1[N101='PR']/N102"}

  def initialize(file)
    @doc = Nokogiri::XML(File.open(file))
    @log = Logger.new('835Transform.log')
  end
  
  def transform
    eobitms = nil
    chk = nil
    eob = nil
    pay = nil
    i = 0

    log.info ">>Transformation Starts"
    begin
      log.info "Total number of batches to process: #{doc.xpath(ITERATORS['BAT_GS']).count()}"
      doc.xpath(ITERATORS["BAT_GS"]).each do |be|
        i = i + 1
        batch = prepare_batch(be,i)
   
        c = be.xpath(ITERATORS["I835"] + "[#{i}]").count()
        log.info "Total number of cheques to process: #{c}"
        be.xpath(ITERATORS["I835"] + "[#{i}]").each do |e|

          pay = prepare_payer(e)
          micr = process_micr(e)
          chk = process_cheque(e)
          chk.payer = pay
          micr.check_informations << chk

          log.info "Number of claims: #{e.xpath(ITERATORS['IEOB']).count()}"
          e.xpath(ITERATORS["IEOB"]).each do |clms|
            eob = process_claim(clms)
            ci = 0

            clms.xpath(ITERATORS["IEOB_ITM"]).each do |clmitms|
              eobitms = process_claim_itms(clmitms)
              eob.service_payment_eobs << eobitms
              ci = ci + 1
            end # eobitms

            log.info " .... Claim itmes: #{ci}"
            chk.insurance_payment_eobs << eob
          end # clms

          job = prepare_job(e,c)
          job.check_informations << chk
          batch.jobs << job
        end # be

        batch.save false
      end # doc
    rescue => bang
      log.error bang
    end

    log.info ">>Transformation Ends"
  end
  
  private
    
  def prepare_batch be, i
    batch = Batch.new(:batchid => Time.now.strftime("%Y%m%d%H%M%S"), 
                      :date => be.xpath(BATCH["date"]).text,
                      :arrival_time => Time.now,
                      :target_time => Time.now,
                      :eob => "TODO",
                      :completion_time => Time.now,
                      :comment => "TODO",
                      :contracted_time => Time.now,
                      :correspondence => false,
                      :bank_deposit_date => Time.now,
                      :lockbox => "TODO",
                      :output_835_generated_time => Time.now,
                      :file_name => "TODO",
                      :cut_number => 1)
    log.info "Preparing batch"
    return batch
  end

  def prepare_job e, c
    j = Job.new(:check_number => e.xpath(CHK["check_number"]).text,
                :tiff_number => "TODO",
                :count => c+1,
                :processor_flag_time => Time.now,
                :processor_target_time => Time.now,
                :qa_flag_time => Time.now,
                :qa_target_time => Time.now,
                :estimated_eob => 1,
                :adjusted_eob => 1,
                :image_count => 1,
                :comment => "TODO",
                :comment_for_qa => "TODO",
                :incomplete_tiff => "TODO",
                :work_queue_flagtime => Time.now,
                :output_835_generated_time => Time.now)
    log.info "Preparing job"
    return j
  end
  
  def prepare_payer e
    pay = Payer.new(:pay_address_one => "Addr1", 
                    :gateway => "TODOGATEWAY", 
                    :payid => "TD", 
                    :payer => e.xpath(PAY["payer"]).text)
    log.info "Preparing payer"
    return pay
  end

  def process_micr e
    return MicrLineInformation.find_or_create_by_aba_routing_number_and_payer_account_number(:aba_routing_number => e.xpath(MICR["aba_routing_number"]).text, :payer_account_number => e.xpath(MICR["payer_account_number"]).text)
  end

  def process_cheque e
    chk_item = CheckInformation.new
    CHK.each {|k,v| chk_item[k] = e.xpath(v).text }
    log.info "Processing Cheque #" + e.xpath(CHK["check_number"]).text
    return chk_item
  end
  
  def process_claim clms
    eob = InsurancePaymentEob.new
    CLAIM.each {|k,v| eob[k] = clms.xpath(v).text }
    log.info " .. Claim #" + clms.xpath(CLAIM["claim_number"]).text
    return eob
  end
 
  def process_claim_itms eobitms
    eob_items = ServicePaymentEob.new
    CLAIM_ITMS.each { |k,v| eob_items[k] = eobitms.xpath(v).text }
    return eob_items
 end

end #class

if ARGV.length > 0
  trnsf = Transformer_835.new(ARGV[0])
  trnsf.transform
else
  puts "ERROR::Unable to process without 835 input file!"
end
