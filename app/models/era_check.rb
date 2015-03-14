class EraCheck < ActiveRecord::Base
  has_many :insurance_payment_eras
  has_many :era_jobs
  has_many :provider_adjustments
  belongs_to :era
  belongs_to :payer

  STATUSES_ORDERED = ['Both', 'Unidentified Site', 'Unidentified Payer']

  scope :exceptions, where("exception_status IS NOT NULL").joins(:era, :era_jobs).order("date(eras.arrival_time) DESC")

  # Returns a case statement for ordering by a particular set of strings
  # Note that the SQL is built by hand and therefore injection is possible,
  # however since we're declaring the priorities in a constant above it's
  # safe.
  def self.order_by_case
    ret = "CASE"
    STATUSES_ORDERED.each_with_index do |p, i|
      ret << " WHEN exception_status = '#{p}' THEN #{i}"
    end
    ret << " END"
  end

  scope :by_status, :order => order_by_case

  def self.map_payer(payer, era_check)
    payer.update_attributes(:era_payer_name => era_check.payer_name, :status => "MAPPED")
    era_checks = EraCheck.where(:payer_name => era_check.payer_name, 
                                :trn_payer_company_identifier => era_check.trn_payer_company_identifier, 
                                :payer_address_1 => era_check.payer_address_1,
                                :payer_address_2 => era_check.payer_address_2,
                                :payer_city => era_check.payer_city,
                                :payer_state => era_check.payer_state,
                                :payer_zip => era_check.payer_zip)
    era_checks.each do |ec|
      ec.update_attributes(:payer_id => payer.id, :status => "MAPPED")

      if ec.exception_status == "Both"
        ec.update_attributes(:exception_status => "Unidentified Site")
      else
        ec.update_attributes(:exception_status => nil)
      end
    end
  end

end
