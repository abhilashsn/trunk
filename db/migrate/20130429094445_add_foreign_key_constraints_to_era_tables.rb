class AddForeignKeyConstraintsToEraTables < ActiveRecord::Migration
  def up
    #execute "ALTER TABLE eras ADD CONSTRAINT FK_eras_inbound_file FOREIGN KEY (inbound_file_information_id)
    #REFERENCES inbound_file_informations(id)"
    #execute "ALTER TABLE era_jobs 
    #ADD CONSTRAINT FK_era_jobs_era FOREIGN KEY (era_id) REFERENCES eras(id),
    #ADD CONSTRAINT FK_era_jobs_era_check FOREIGN KEY (era_check_id) REFERENCES era_checks(id),
    #ADD CONSTRAINT FK_era_jobs_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
    #ADD CONSTRAINT FK_era_jobs_client FOREIGN KEY (client_id) REFERENCES clients(id)"
    #execute "ALTER TABLE era_checks 
    #ADD CONSTRAINT FK_era_checks_era FOREIGN KEY (era_id) REFERENCES eras(id),
    #ADD CONSTRAINT FK_era_checks_payer FOREIGN KEY (payer_id) REFERENCES payers(id)"
    #execute "ALTER TABLE insurance_payment_eras ADD CONSTRAINT FK_ins_pay_eras_era_check FOREIGN KEY (era_check_id)
    #REFERENCES era_checks(id)"
    #execute "ALTER TABLE service_payment_eras ADD CONSTRAINT FK_service_pay_eras_ins_pay_era FOREIGN KEY (insurance_payment_era_id)
    #REFERENCES insurance_payment_eras(id)"
    #execute "ALTER TABLE misc_segments_eras ADD CONSTRAINT FK_misc_seg_eras_era FOREIGN KEY (era_id) REFERENCES eras(id)"
    #execute "ALTER TABLE claim_level_adjustments_eras ADD CONSTRAINT FK_claim_adjustments_ins_pay_era FOREIGN KEY (insurance_payment_era_id)
    #REFERENCES insurance_payment_eras(id)"
    #execute "ALTER TABLE service_level_adjustments_eras ADD CONSTRAINT FK_service_adjustments_service_pay_era FOREIGN KEY (service_payment_era_id)
    #REFERENCES service_payment_eras(id)"
    #execute "ALTER TABLE era_exceptions ADD CONSTRAINT FK_era_exception_era FOREIGN KEY (era_id)
    #REFERENCES eras(id)"
    #execute "ALTER TABLE era_provider_adjustments ADD CONSTRAINT FK_provider_adj_era_check FOREIGN KEY (era_check_id)
    #REFERENCES era_checks(id)"
  end

  def down
     execute "ALTER TABLE eras DROP FOREIGN KEY FK_eras_inbound_file"
     execute "ALTER TABLE era_jobs 
    DROP FOREIGN KEY FK_era_jobs_era,
    DROP FOREIGN KEY FK_era_jobs_era_check,
    DROP FOREIGN KEY FK_era_jobs_facility,
    DROP FOREIGN KEY FK_era_jobs_client"
     execute "ALTER TABLE era_checks 
    DROP FOREIGN KEY FK_era_checks_era,
    DROP FOREIGN KEY FK_era_checks_payer"
     execute "ALTER TABLE insurance_payment_eras DROP FOREIGN KEY FK_ins_pay_eras_era_check"
     execute "ALTER TABLE service_payment_eras DROP FOREIGN KEY FK_service_pay_eras_ins_pay_era"
     execute "ALTER TABLE misc_segments_eras DROP FOREIGN KEY FK_misc_seg_eras_era"
     execute "ALTER TABLE claim_level_adjustments_eras DROP FOREIGN KEY FK_claim_adjustments_ins_pay_era"
     execute "ALTER TABLE service_level_adjustments_eras DROP FOREIGN KEY FK_service_adjustments_service_pay_era"
     execute "ALTER TABLE era_exceptions DROP FOREIGN KEY FK_era_exception_era"
     execute "ALTER TABLE era_provider_adjustments DROP FOREIGN KEY FK_provider_adj_era_check"
  end
end
