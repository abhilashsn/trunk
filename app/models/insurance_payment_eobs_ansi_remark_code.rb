class InsurancePaymentEobsAnsiRemarkCode < ActiveRecord::Base
   belongs_to :insurance_payment_eob
   belongs_to :ansi_remark_code
end
