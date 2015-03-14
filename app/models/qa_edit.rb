# Track QA Edits in datacapture process against an EOB (Insurance or Next Gen) object
# Ruby Tip : The class variable name should not be same as DB column name,
#  If did so, the DB column will be saved as the value of class variable defined within the class scope

# The record creation for qa_edit gets invoked from saving each model object from DataCapturesController.
# The user_id, insurance_payment_eob_id, patient_pay_eob_id, service_payment_eob_id are
#  same for all the records created in qa_edits for one request response.
#  This is because the records are saved against the EOB object and the EOB object is only one for one request response.
#
# The class variables will be initialized in DatacapturesController.
# Class accssor is used to asign values to class variable

class QaEdit < ActiveRecord::Base

  cattr_accessor :qa_user_id, :svc_line_id, :insurance_eob_id, :next_gen_eob_id
  @@qa_user_id, @@svc_line_id = nil, nil
  @@insurance_eob_id, @@next_gen_eob_id = nil, nil

  # This method gives a wrapper to create records for an object, for which the qa edits are tracked
  # Input :
  # object : instance of InsurancePaymentEob, PatientPayEob, CheckInformation, Payer, MicrLineInformation etc for which the qa edits are to be tracked
  def self.create_records(object)
    if !@@qa_user_id.blank? && object.changed?
      qa_user_id = @@qa_user_id.to_i
      insurance_eob_id = @@insurance_eob_id.to_i if !@@insurance_eob_id.blank?
      next_gen_eob_id = @@next_gen_eob_id.to_i if !@@next_gen_eob_id.blank?
      if object.class == ServicePaymentEob
        svc_line_id = object.id
      end

      qa_edit_records = []
      object.changed_attributes.each do |attribute, value|
        
        if !['created_at', 'updated_at', 'details'].include?(attribute)
          changed_values = object.send("#{attribute}_change")
          previous_value = changed_values[0]
          current_value = changed_values[1]

          qa_edit_records << self.new(:field_name => attribute,
            :previous_value => previous_value,
            :current_value => current_value,
            :user_id => qa_user_id,
            :insurance_payment_eob_id => insurance_eob_id,
            :patient_pay_eob_id => next_gen_eob_id,
            :service_payment_eob_id => svc_line_id)
        end
      end
      self.import qa_edit_records if !qa_edit_records.blank?
    end
  end

  def get_reason_code id
    ReasonCode.find(id)
  end

end
