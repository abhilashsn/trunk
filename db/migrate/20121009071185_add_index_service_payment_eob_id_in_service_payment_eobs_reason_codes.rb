class AddIndexServicePaymentEobIdInServicePaymentEobsReasonCodes < ActiveRecord::Migration
  def change
    add_index :service_payment_eobs_reason_codes, :service_payment_eob_id, :name => "idx_sperc_service_payment_eob_id"
  end
end


