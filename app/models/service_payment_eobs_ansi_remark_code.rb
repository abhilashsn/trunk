class ServicePaymentEobsAnsiRemarkCode < ActiveRecord::Base
   belongs_to :service_payment_eob
   belongs_to :ansi_remark_code
end
