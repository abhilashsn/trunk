class PatientPayEob < ActiveRecord::Base
  include DcGrid
  belongs_to :check_information
  has_many :mpi_statistics_reports, :as => :eob, :dependent => :destroy
  has_many :eob_qas, :conditions => {:eob_type_id => 2}, :foreign_key => "eob_id", :dependent => :destroy
  has_many :eobs_output_activity_logs, :dependent => :destroy
  has_many :output_activity_logs, :through => :eobs_output_activity_logs
  has_many :client_activity_logs, :as => :eob
  after_update :create_qa_edit

  before_save do |obj|
    obj.default_values_uid
    obj.upcase_grid_data(['document_classification'])
  end

  def create_qa_edit
    QaEdit.create_records(self)
  end

  def default_values_uid
    self.uid ||= Sequence.get_next('Eob_uid')
  end

  def self.total_amount(check_info_id)
    patient_pay_amount = PatientPayEob.find(:all,:conditions => "check_information_id = #{check_info_id}",:select => "sum(stub_amount) amount",:group => "check_information_id")
    unless patient_pay_amount.blank?
      patient_pay_amount.each do |amount|
        @total_amount = amount.amount
      end
    else
      @total_amount = "0.00"
    end
    return @total_amount
  end

  def self.statement_amount(check_info_id)
    patient_pay_eobs  = PatientPayEob.find(:all,:conditions => "check_information_id = #{check_info_id}")
    patient_pay_eobs.each  do |patient_pay|
      if !patient_pay.statement_amount.blank?
        @statementamount = patient_pay.statement_amount
      else
        @statementamount =0.00
      end
    end
    return @statementamount
  end

  def self.stub_amount(check_info_id)
    patient_pay_eobs  = PatientPayEob.find(:all,:conditions => "check_information_id = #{check_info_id}")
    patient_pay_eobs.each  do |patient_pay|
      if !patient_pay.stub_amount.blank?
        @stubamt = patient_pay.stub_amount
      else
        @stubamt =0.00
      end
    end
    return @stubamt
  end

  def self.statement_and_stub_amount(check_info_id)
    patient_pay_eobs  = PatientPayEob.where("check_information_id = #{check_info_id}")
    patient_pay_eobs.each  do |patient_pay|
      if !patient_pay.statement_amount.blank? or !patient_pay.stub_amount.blank?
        @statementamount = patient_pay.statement_amount
        @stubamt = patient_pay.stub_amount
      else
        @statementamount = 0.00
        @stubamt = 0.00
      end
    end
    return @statementamount, @stubamt
  end

  # Calculating processor_input_field_count in patient_pay_eob level
  # by checking constant fields in grid
  def processor_input_field_count
    constant_fields = [account_number, transaction_date, statement_amount,
      stub_amount, patient_last_name, patient_suffix, patient_first_name,
      patient_middle_initial]
    constant_fields_with_data = constant_fields.select{|field| !field.blank?}
    total_field_count_with_data = constant_fields_with_data.length
    total_field_count_with_data
  end

  def normalised_eob(fac_name)
    normalised_eob = Facility.find_by_name(fac_name).details["claim_normalized_factor"]
    if normalised_eob.nil? || normalised_eob == ""
      return 0
    else
      return normalised_eob
    end
  end

  def self.page_number(check_information_id, eob_id)
    id_array = []
    eobs = self.find(:all,:conditions => "check_information_id = #{check_information_id} ", :select => "id, account_number")
    id_array = eobs.map(&:id)
    page = id_array.index(eob_id)
    page = page || 0
    page += 1
    page
  end

  def self.amount_so_far(check_info_id)
    if check_info_id
      total_amount = PatientPayEob.sum('stub_amount', :conditions => ["check_information_id = ?", check_info_id])
    end
    total_amount.to_f
  end

  def normalize_account_number(practice_id_config)
    practice_id_config = practice_id_config.to_s
    normalized_account_number = account_number.to_s
    account_number_length = account_number.length
    if account_number_length < 16 && !practice_id_config.blank?
      if account_number_length < 12
        normalized_account_number = account_number.rjust(12, '0')
      end
      normalized_account_number = practice_id_config + normalized_account_number
    end
    normalized_account_number
  end

end
