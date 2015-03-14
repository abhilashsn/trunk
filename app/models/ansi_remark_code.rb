class AnsiRemarkCode < ActiveRecord::Base
  has_many :reason_codes_ansi_remark_codes, :dependent => :destroy
  has_many :reason_codes, :through => :reason_codes_ansi_remark_codes
  has_many :service_payment_eobs_ansi_remark_codes, :dependent => :destroy

  validates_presence_of :adjustment_code
  validates_presence_of :adjustment_code_description
  validates_uniqueness_of :adjustment_code

end
