class FacilityOutputConfig < ActiveRecord::Base

	include OutputFacilityOutputConfig
	
  belongs_to :facility
  validates_presence_of :file_name ,:if => :check_grouping
  has_details :isa_06 => :string,
    :bpr_16 => :string,
    :bpr_16_correspondence => :string,
    :zero_pay => :string,
    :plb_separator => :string,
    :interest_amount => :string,
    :payee_name => :string

  serialize :operation_log_config
  # Fetches the insurance payment eob's output configuration record/s for a facility id
  scope :insurance_eob,
    lambda{ |facility_id| { :conditions => ["(report_type != 'Operation Log' or report_type is null) and
                            eob_type = 'Insurance EOB' and facility_id = #{facility_id}"]}}
  
  # Fetches the patient payment eob's output configuration record/s for a facility id
  scope :patient_eob,
    lambda{ |facility_id| { :conditions => ["(report_type != 'Operation Log' or report_type is null) and
                            eob_type = 'Patient Payment' and facility_id = #{facility_id}"]}}

  # Fetches the Operation Log configuration record/s for a facility id
  scope :operation_log,
    lambda{ |facility_id| { :conditions => {:report_type => "Operation Log",
        :facility_id => facility_id}}}

  scope :other_outputs,
    lambda{ |facility_id| { :conditions => {:report_type => "Other Outputs",
        :facility_id => facility_id}}}


  scope :eob_output_type,:conditions=> "eob_type = 'Insurance EOB' and report_type = 'Output' and format='835'"
  # Assigns weights to each 'grouping'
  # based on the size of data
  # For example, 'By Batch Date' is larger than 'By Cut' since a date may include many cuts
  
  def grouping_weight
    case grouping
    when 'By Lockbox And Date'
      10
    when 'Nextgen Grouping'
      9
    when 'By Batch Date'
      8
    when 'By Cut And Extension'
      7  
    when 'By Payer By Batch Date'
      6
    when 'By Payer Id By Batch Date'
      5
    when 'By Cut And Payerid'
      4
    when 'By Cut'
      3
    when 'By Batch'
      2
    when 'By Payer'
      1
    else
      0
    end
  end

  def check_grouping
    output_groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
    return true  if !output_groupings.include?(grouping)
  end
  
end
