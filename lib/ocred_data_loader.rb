class OcredDataLoader
  attr_accessor :ocr_xml, :job
  def initialize(ocr_xml)
    self.ocr_xml = ocr_xml
  end

  def perform
    job_id = File.basename(self.ocr_xml).split(".").first
    self.job = Job.find(job_id)
    if job_can_be_ocred
      require 'ocr/ocr_xml_parser'
      ocr = OcrXmlParser::OcrParser.new(self.ocr_xml)
      parse_results = ocr.parse
      update_job  parse_results
    end
  end
  
  private

  def job_can_be_ocred
    if self.job.job_status == JobStatus::OCR
      self.job.update_attribute(:ocr_status, JobStatus::OCR_PROCESSING)
      true
    else
      false
    end    
  end
  
  def update_job parse_results
    status, messages, total_ocr_fields, total_confident_fields = parse_results
    if status == "SUCCESS"
      self.job.update_attributes({:ocr_status => JobStatus::OCR_SUCCESS, :job_status => JobStatus::NEW,
                                   :total_ocr_fields => total_ocr_fields , :total_high_confidence_fields => total_confident_fields})

    elsif status == "EXCEPTION"
      self.job.update_attribute(:ocr_status, JobStatus::OCR_EXCEPTION)
      self.job.update_attribute(:job_status, JobStatus::NEW)
    end

  end
end
