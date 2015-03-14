class ClaimValidationException < ActiveRecord::Base
    belongs_to :eob, :class_name  => "InsurancePaymentEob", :foreign_key => "insurance_payment_eob_id"
	belongs_to :claim, :class_name => "ClaimInformation", :foreign_key => "claim_information_id"

    validates :insurance_payment_eob_id, :presence => true
    validates :claim_information_id, :presence => true
    validates :action, :presence => true

	delegate :check_information, :to => :eob
	delegate :batch, :to => :check_information
	delegate :payer, :to => :check_information
	delegate :batchid, :to => :batch
	delegate :date, :to => :batch, :prefix => true
	delegate :client, :to => :batch
	delegate :facility, :to => :batch
	delegate :name, :to => :client, :prefix => true
    delegate :name, :to => :facility, :prefix => true
    delegate :patient_account_number, :to => :eob, :prefix => true
    delegate :patient_account_number, :to => :claim, :prefix => true
    delegate :patient_last_name, :to => :eob, :prefix => true
    delegate :patient_last_name, :to => :claim, :prefix => true
    delegate :claim_type, :to => :eob, :prefix => true
    delegate :claim_type_normalized, :to => :claim, :prefix => true
    delegate :payer_name, :to => :claim, :prefix => true

    def eob_charges
    	"0.00"
    end

    def claim_charges
    	"0.00"
    end
end
