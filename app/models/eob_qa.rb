# == Schema Information
# Schema version: 69
#
# Table name: eob_qas
#
#  id                     :integer(11)   not null, primary key
#  processor_id           :integer(11)
#  qa_id                  :integer(11)
#  job_id                 :integer(11)
#  time_of_rejection      :datetime
#  account_number         :string(255)
#  total_fields           :integer(11)
#  total_incorrect_fields :integer(11)
#  status                 :string(255)
#  total_qa_checked       :integer(11)
#  comment                :string(255)
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class EobQa < ActiveRecord::Base
  #  validates_presence_of :payer, :account_number, :total_fields, :total_incorrect_fields, :message => " is required."
  #  validates_numericality_of :total_fields, :total_incorrect_fields, :message => " is not a number"
  belongs_to :processor, :class_name => "User", :foreign_key => :processor_id
  belongs_to :qa, :class_name => "User", :foreign_key => :qa_id
  belongs_to :job
  belongs_to :eob_error
  belongs_to :insurance_payment_eob
  belongs_to :patient_pay_eob

  def patient_pay_eob
    PatientPayEob.find(eob_id) if eob_type_id != 1
  end

  def insurance_payment_eob
    InsurancePaymentEob.find(eob_id) if eob_type_id == 1
  end

  def self.initialize_and_create(error_record_ids_to_create, parameters = {})
    eob_qa_records_to_create = []
    count = 0
    error_record_ids_to_create.each do |error_record_id|
      count += 1
      eob_qa = EobQa.initialize_entity(error_record_id, count, parameters)      
      eob_qa_records_to_create << eob_qa
    end
    EobQa.import eob_qa_records_to_create if eob_qa_records_to_create.present?
  end

  def self.initialize_entity(error_record_id, count, parameters = {})
    eob_obj = parameters[:eob_obj]
    eob_qa = EobQa.new
    eob_qa.job_id = parameters[:job_id]
    eob_qa.qa_id = parameters[:qa_id]
    eob_qa.eob_error_id = error_record_id
    eob_qa.associate_eob_details(eob_obj)
    eob_qa.time_of_rejection = Time.now
    eob_qa.comment = parameters[:qa_comment]
    eob_qa.total_incorrect_fields = (count == 1) ? parameters[:total_incorrect_fields] : 0
    eob_qa.status = parameters[:status]
    eob_qa.prev_status = parameters[:prev_status]
    eob_qa.payer = 1
    eob_qa
  end

  def associate_eob_details(eob_obj)
    if eob_obj
      self.eob_id = eob_obj.id
      self.processor_id = eob_obj.processor_id
      self.eob_type_id = (eob_obj.class.name == "PatientPayEob") ? 2 : 1
    end
  end
  
end
