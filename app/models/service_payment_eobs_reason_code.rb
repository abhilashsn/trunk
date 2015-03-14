class ServicePaymentEobsReasonCode < ActiveRecord::Base
   belongs_to :service_payment_eob
   belongs_to :reason_code
end
