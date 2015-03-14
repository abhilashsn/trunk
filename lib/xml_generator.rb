require 'utils/rr_logger'
require 'other_output_types'
class XmlGenerator
  attr_accessor :batches_for_xml, :batch_xml, :transaction_xml, :claim_xml,
    :service_xml, :batch, :facility

  def initialize(batch_id)
    @batch = Batch.find(:first, :conditions => ["(status = ? OR status = ? OR status = ? ) AND id = ?", BatchStatus::OUTPUT_READY, BatchStatus::OUTPUT_GENERATED, BatchStatus::OUTPUT_EXCEPTION, batch_id],
      :include => [:output_activity_logs, :facility, {:jobs => :check_informations}])
    if @batch
      @bank_batch_id =  batch.index_batch_number
      @facility = batch.facility
      @dir = "private/data/XMLs/#{Date.today}/#{batch.batchid}"
    else
      puts "Batch with id #{batch_id} is not OUTPUT_READY. Batch must have status 'OUTPUT_READY' for XML generation."
    end    
  end

  def generate
    if batch_eligible_for_etl_xml_generation?
      generate_batch_xml
      generate_transaction_xml
      generate_claim_xml
      generate_service_xml
      true
    end    
  rescue Exception => e
    log.error "Exception  => " + e.message
    log.error e.backtrace.join("\n")
    false
  end  

  private ################################## private methods##################################

  def batch_eligible_for_etl_xml_generation?
    ready = true
    if @batch.output_activity_logs.length < 1
      puts "XML output can be generated only after all other types of outputs have been generated"
    elsif @batch.facility.facility_output_configs.length > 0
      applicable_oth_ops = @batch.facility.facility_output_configs.map(&:other_output_type)
      generated_output_formats = @batch.output_activity_logs.map(&:file_format)
      applicable_oth_ops.each do |oth_op|
        if oth_op == OtherOutputTypes::HREOB
          ready &&= generated_output_formats.include?'HREOB'
        elsif oth_op == OtherOutputTypes::A37
          ready &&= generated_output_formats.include?'A37'
        end
      end
      ready &&= generated_output_formats.include?'835'
    end
    if not ready
      puts "***********************************************************************************"
      puts "Please ensure all outputs that are configured, are generated before XML generation"
      puts "***********************************************************************************"
    end
    ready
  end

  def create_xml_builder
    Builder::XmlMarkup.new(:indent => 2)
  end

  def generate_batch_xml
    @batch_xml = create_xml_builder_object

    batch_xml.load_set do |inner_xml|
      generate_edc_header(batch_xml, 'batch')
      generate_batch_set
      generate_batch_doc_set
      generate_batch_trailer
    end
    
    file_name = get_file_name('batch')
    create_file(batch_xml, @dir, file_name)
    
    if File.file?("#{@dir}/#{file_name}")
      save_output_activity('EDC Batch XML Generated', batch.id, file_name, @dir)
    end
  end

  def generate_transaction_xml
    @transaction_xml = create_xml_builder_object

    transaction_xml.load_set do |inner_xml|
      generate_edc_header(transaction_xml, 'transaction')
      transaction_set_count = generate_transaction_set
      doc_set_count = generate_transaction_doc_set
      generate_check_trailer(transaction_set_count, doc_set_count)
    end

    file_name = get_file_name('transaction')
    create_file(transaction_xml, @dir, file_name)
    
    if File.file?("#{@dir}/#{file_name}")
      save_output_activity('EDC Transaction XML Generated', batch.id, file_name, @dir)
    end

  end

  def generate_claim_xml
    @claim_xml = create_xml_builder_object

    claim_xml.load_set do |inner_xml|
      generate_edc_header(claim_xml, 'claim payment')
      claim_payment_count = generate_claim_payment_set
      doc_count = generate_claim_doc_set
      claim_adjustment_count, unmapped_codes =
        generate_claim_payment_adjustment_set
      generate_claim_payer_reason_set(unmapped_codes)
      generate_claim_trailer(claim_payment_count, doc_count,
        claim_adjustment_count, unmapped_codes.length)
    end

    file_name = get_file_name('claim_payment')
    create_file(claim_xml, @dir, file_name)

    if File.file?("#{@dir}/#{file_name}")
      save_output_activity('EDC Claim XML Generated', batch.id, file_name, @dir)
    end

  end

  def generate_service_xml
    @service_xml = create_xml_builder_object
    service_line_count = 0
    batch.checks_having_payers.each do |check|
      check.insurance_payment_eobs.each do |eob|
        service_line_count += eob.service_payment_eobs.count
      end
    end
    service_xml.load_set do |inner_xml|
      if service_line_count > 0
        generate_edc_header(service_xml, 'service')
        service_payment_count = generate_service_set
        service_adjustment_count, unmapped_codes =
          generate_service_adjustment_set
        generate_service_payer_reason_set(unmapped_codes)
        generate_service_trailer(service_payment_count, service_adjustment_count,
          unmapped_codes.length)
      end
    end

    file_name = get_file_name('service')
    create_file(service_xml, @dir, file_name)

    if File.file?("#{@dir}/#{file_name}")
      save_output_activity('EDC Service XML Generated', batch.id, file_name, @dir)
    end

  end

  def get_file_name(type)
    site_code = facility.sitecode
    site_code = site_code.length > 3 ? site_code.slice(-3, 3) : site_code.rjust(3, '0')
    
    if not @bank_batch_id.blank?
      "EDC_#{ type.upcase }_#{ batch.date.strftime("%y%m%d") }#{batch.cut.rjust(2,"0")}#{ site_code }_#{ (@bank_batch_id.to_i.to_s(36).upcase).rjust(3, '0') }.XML"
    else
      puts "----------------------------------------------------------------------"
      puts "Bank Batch ID (index_batch_number) is null, XML output cannot be generated"
      puts "----------------------------------------------------------------------"
    end
  end

  def create_xml_builder_object
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml
  end

  def generate_batch_set
    batch_xml.batch_set do |inner_xml|
      batch.batch_xml(batch_xml)
    end
  end

  def generate_batch_doc_set
    batch_xml.doc_set do |inner_xml|
      batch.doc_xml(batch_xml)
    end
  end

  def generate_transaction_set
    transaction_set_count = 0
    transaction_xml.transaction_set do |inner_xml|
      batch.checks_having_payers.each_with_index do |check, j|        
        transaction_set_count = check.tran_xml(transaction_xml, j, check.job, batch, transaction_set_count)
      end
    end
    transaction_set_count
  end

  def generate_transaction_doc_set
    doc_set_count = 0
    transaction_xml.doc_set do |inner_xml|
      batch.checks_having_payers.each_with_index do |check, j|
        doc_set_count = check.doc_xml(transaction_xml, j, doc_set_count)
      end
    end
    doc_set_count
  end

  def generate_claim_payment_set
    claim_payment_count = 0
    transaction_count = 0
    claim_xml.claim_payment_set do |inner_xml|
      batch.checks_having_payers.each do |check|
        check.eobs.each do |eob|
          claim_payment_count = eob.claim_payment_xml(claim_xml, 
            claim_payment_count, transaction_count, @facility, @batch)
        end
        transaction_count += 1
      end
    end
    claim_payment_count
  end

  def generate_claim_doc_set
    doc_set_count = 0
    claim_payment_count = 0
    claim_xml.doc_set do |inner_xml|
      batch.checks_having_payers.each do |check|
        check.eobs.each do |eob|
          doc_set_count, claim_payment_count =  eob.doc_xml(claim_xml, doc_set_count, claim_payment_count)
        end
      end
    end
    doc_set_count
  end

  def generate_claim_payment_adjustment_set
    unmapped_codes = []
    unmapped_codes_for_eob = []
    claim_adjustment_count = 0
    claim_payment_count = 0
    claim_xml.claim_payment_adjustment_set do |inner_xml|
      batch.checks_having_payers.each do |check|
        payer = check.get_payer
        check.eobs.each do |eob|
          claim_payment_count, claim_adjustment_count, unmapped_codes_for_eob = eob.claim_adjustment_xml(
            claim_xml, claim_payment_count, facility, payer, claim_adjustment_count)
          unmapped_codes.concat(unmapped_codes_for_eob)
        end
      end
    end
    return claim_adjustment_count, unmapped_codes.compact
  end

  def generate_claim_payer_reason_set(unmapped_codes)    
    claim_xml.claim_payment_payer_reason_set do
      if unmapped_codes && unmapped_codes.length > 0
        unmapped_codes.each_with_index do |rc_claim_elem, index|
          rc = rc_claim_elem[0]
          description = rc_claim_elem[1]
          claim_attribute = rc_claim_elem[2]
          claim_xml.claim_payment_payer_reason(:ID => index + 1) do
            claim_xml.tag!(:claim_payment_attrib, claim_attribute)
            claim_xml.tag!(:payer_reason_cd, rc)
            claim_xml.tag!(:payer_reason_de, description.strip)
          end
        end
      end
    end
  end

  def generate_service_set
    service_payment_count = 0
    claim_payment_count = 0
    transaction_count = 0
    service_xml.service_set do |inner_xml|
      batch.checks_having_payers.each do |check|
        check.eobs.each do |eob|
          eob.service_payment_eobs.each_with_index do |service, l|
            service_payment_count = service.service_xml(service_xml, l, service_payment_count,
              claim_payment_count, transaction_count, @facility)
          end
          claim_payment_count += 1
        end
        transaction_count += 1
      end
    end
    service_payment_count
  end

  def generate_service_adjustment_set
    unmapped_codes = []
    unmapped_codes_per_svc = []
    service_adjustment_count = 0
    service_payment_count = 0
    service_xml.service_adjustment_set do |inner_xml|
      batch.checks_having_payers.each do |check|
        payer = check.get_payer
        check.eobs.each do |eob|
          eob.service_payment_eobs.each do |service|
            service_adjustment_count, service_payment_count, unmapped_codes_per_svc =
              service.service_adjustment_xml(service_xml, service_payment_count,
              facility, payer, service_adjustment_count)
            unmapped_codes.concat(unmapped_codes_per_svc)
          end
        end
      end
    end
    return service_adjustment_count, unmapped_codes.compact
  end

  def generate_service_payer_reason_set(unmapped_codes)    
    service_xml.service_payer_reason_set do
      if unmapped_codes && unmapped_codes.length > 0
        unmapped_codes.each_with_index do |rc_svc_elem, index|
          rc = rc_svc_elem[0]
          description = rc_svc_elem[1]
          svc_attribute = rc_svc_elem[2]
          service_xml.service_payer_reason(:ID => index + 1) do
            service_xml.tag!(:service_attrib, svc_attribute)
            service_xml.tag!(:payer_reason_cd, rc)
            service_xml.tag!(:payer_reason_de, description.strip)
          end
        end
      end
    end
  end

  def create_file(xml, dir, file_name)
    str = xml.to_s.gsub("<to_s/>", '')
    FileUtils.mkdir_p(dir)
    f = File.new("#{dir}/#{file_name}",  "w")
    f.write(str)
  end

  def generate_edc_header(builder, type)
    outputs = batch.output_activity_logs
    if outputs && outputs.length > 0
      extract_date = outputs.last.start_time.strftime("%Y-%m-%d")
    end
    builder.tag!(:header) do
      builder.tag!(:load_type, 'PERIODIC')
      builder.tag!(:interface_type, type.upcase!)
      builder.tag!(:source_type, 'EDC')
      builder.tag!(:source_system_cd, 'RM')
      builder.tag!(:source_file_name, batch.file_name)
      builder.tag!(:extract_start_date, extract_date)
      builder.tag!(:extract_end_date, extract_date)
      builder.tag!(:process_date, Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      builder.tag!(:process_server)
      builder.tag!(:job_stream)
    end
  end

  def generate_batch_trailer
    batch_xml.trailer do
      batch_xml.tag!(:batch_set_count, 1)
      batch_xml.tag!(:doc_set_count, batch.primary_output_files.count)
    end
  end

  def generate_check_trailer(transaction_set_count, doc_set_count)
    transaction_xml.trailer do
      transaction_xml.tag!(:transaction_set_count, transaction_set_count)
      transaction_xml.tag!(:doc_set_count, doc_set_count)
    end
  end

  def generate_claim_trailer(claim_payment_count, doc_count,
      claim_adjustment_count, claim_payer_reason_set_count)
    claim_xml.trailer do
      claim_xml.tag!(:claim_payment_set_count, claim_payment_count)
      claim_xml.tag!(:doc_set_count, doc_count)
      claim_xml.tag!(:claim_payment_adjustment_set_count, claim_adjustment_count)
      claim_xml.tag!(:claim_payment_payer_reason_set_count, claim_payer_reason_set_count)
    end
  end

  def generate_service_trailer(service_payment_count, service_adjustment_count, service_payer_reason_set_count)
    service_xml.trailer do
      service_xml.tag!(:service_set_count, service_payment_count)
      service_xml.tag!(:service_adjustment_set_count, service_adjustment_count)
      service_xml.tag!(:service_payer_reason_set_count, service_payer_reason_set_count)
    end
  end

  def log
    RevRemitLogger.new_logger(LogLocation::XOPLOG)
  end

  def save_output_activity(activity, batch_id, file_name, file_location)
    output_activity = OutputActivityLog.new()
    output_activity.batch_id = batch_id
    output_activity.user_id = 1
    output_activity.activity = activity
    output_activity.start_time = Time.now
    output_activity.file_name = file_name
    output_activity.file_format = 'ETL_XML'
    output_activity.file_location = file_location
    output_activity.file_size = File.size?("#{file_location}/#{file_name}").to_i
    output_activity.save
  end
end
