class Output835::QuadaxCheck < Output835::Check

  def transaction_set_line_number(index)
    elements = []
    elements << 'LX'
    elements << index.to_s
    elements.join(@element_seperator)
  end

   # Reports adjustments to the actual payment that are NOT
  # specific to a particular claim or service
  # These adjustments can either decrease the payment (a positive
  # number) or increase the payment (a negative number)
  # such as the remainder of check amount subtracted by total eob payemnts (provider adjustment)
  # or interest amounts of eobs etc.
  # On PLB segment this adjustment amount and interest amount should
  # always print with opposite sign.
  def provider_adjustment
    eob_klass = Output835.class_for("Eob", facility)
    eob_obj = eob_klass.new(eobs.first, facility, payer, 1, @element_seperator) if eobs.first

    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    code, qual = eob_obj.service_payee_identification
    provider_adjustments = get_provider_adjustment
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    provider_adjustment_group_keys = provider_adjustment_groups.keys
    provider_adjustment_group_values = provider_adjustment_groups.values
    start_index = 0
    array_length = 6
    provider_adjustment_to_print = []
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = facility.client.group_code.to_s.strip
      provider_adjustment_group_length = provider_adjustment_group_keys.length
      remaining_provider_adjustment_group = provider_adjustment_group_length % array_length
      total_number_of_plb_seg = (remaining_provider_adjustment_group == 0)?
          (provider_adjustment_group_length / array_length):
          ((provider_adjustment_group_length / array_length) + 1)
      plb_seg_number = 0
      provider_adjustment_final = []

      while(plb_seg_number < total_number_of_plb_seg)
        provider_adjustment_groups_new = provider_adjustment_group_values[start_index,array_length]
        unless provider_adjustment_groups_new.blank?
          plb_seg_number += 1
          start_index = array_length * plb_seg_number
          provider_adjustment_elements = []
          provider_adjustment_elements << 'PLB'
          provider_adjustment_elements << code
          provider_adjustment_elements << year_end_date
          plb_separator = facility_output_config.details["plb_separator"]
          provider_adjustment_groups_new.each do |prov_adj_grp|
            plb_03 = prov_adj_grp.first.qualifier.to_s.strip
            if !prov_adj_grp.first.patient_account_number.blank?
              plb_03 += plb_separator.to_s.strip + prov_adj_grp.first.patient_account_number.to_s.strip
              adjustment_amount = prov_adj_grp.first.amount
            else
              adjustment_amount = 0
              prov_adj_grp.each do |prov_adj|
                adjustment_amount = adjustment_amount.to_f + prov_adj.amount.to_f
              end
            end
            plb_03 = 'WO' if facility_group_code == 'ADC'
            provider_adjustment_elements << plb_03
            provider_adjustment_elements << (format_amount(adjustment_amount) * -1)
          end
          if interest_eobs && interest_eobs.length > 0 && !facility.details[:interest_in_service_line] &&
              facility_output_config.details[:interest_amount] == "Interest in PLB"
            interest_eobs.each do |eob|
              plb05 = 'L6:'+ eob.patient_account_number
              plb05 = 'L6' if facility_group_code == 'ADC'
              provider_adjustment_elements << plb05
              provider_adjustment_elements << (eob.amount('claim_interest') * -1)
            end
          end
          provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
          provider_adjustment_final << provider_adjustment_elements
        end
      end
      provider_adjustment_final.each do |prov_adj_final|
        prov_adj_final_string = prov_adj_final.join(@element_seperator)
        provider_adjustment_to_print << prov_adj_final_string
      end
    end
    if provider_adjustment_to_print.empty? && interest_exists_and_should_be_printed && facility_output_config.details[:interest_amount] == "Interest in PLB"
      parts = [interest_eobs[0..5], interest_eobs[5..-1] ]
      parts.each do |interest_eobs|
        if interest_eobs
          provider_adjustments = ['PLB',code,year_end_date]
          interest_eobs.each do |eob|
            provider_adjustments << 'L6:'+ eob.patient_account_number
            provider_adjustments << (eob.amount('claim_interest') * -1)
          end
          provider_adjustment_to_print << provider_adjustments.join(@element_seperator)
        end
      end
      provider_adjustment_to_print
    else
      provider_adjustment_to_print
    end
  end

end