class EobsOutputActivityLog < ActiveRecord::Base
  belongs_to :output_activity_log  
  belongs_to :insurance_payment_eob
  belongs_to :patient_pay_eob
  
  validates_presence_of :output_activity_log_id
  validate :presence_of_foreign_keys
  
  def presence_of_foreign_keys
    if !(insurance_payment_eob_id.blank? || patient_pay_eob_id.blank?)
      errors[:base] << "A reference to InsurancePaymentEob or PatientPayEob should be present."
    end    
  end
  
end
