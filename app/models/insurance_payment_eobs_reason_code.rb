class InsurancePaymentEobsReasonCode < ActiveRecord::Base
   belongs_to :insurance_payment_eob
   belongs_to :reason_code
end
