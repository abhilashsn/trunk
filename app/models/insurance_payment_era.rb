class InsurancePaymentEra < ActiveRecord::Base

    belongs_to :era_check
    has_many :service_payment_eras

end
