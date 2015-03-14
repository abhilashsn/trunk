class Output835::SouthNassauCommunityHospitalTemplate < Output835::OrbTestFacilityTemplate

  def effective_payment_date
    if @is_correspndence_check && (!@check.check_date.blank?)
      @check.check_date.strftime("%Y%m%d")
    else
      date_config =  @is_correspndence_check ? @facility_output_config.details[:bpr_16_correspondence] : @facility_output_config.details[:bpr_16]
      if date_config == "Batch Date" || (@check.payment_method == 'ACH' and @check.check_date.blank?)
        @batch.date.strftime("%Y%m%d")
      elsif date_config == "835 Creation Date"
        Time.now.strftime("%Y%m%d")
      elsif date_config == "Check Date"
        @check.check_date.strftime("%Y%m%d")
      end
    end

  end

end