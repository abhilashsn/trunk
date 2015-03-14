module ReasonCodesHelper
  module ClassMethods
    
    def is_adjustment_code_associated?(obj)
      obj.copay_reason_code_id.present? || obj.coinsurance_reason_code_id.present? ||
        obj.contractual_reason_code_id.present? || obj.deductible_reason_code_id.present? ||
        obj.denied_reason_code_id.present? || obj.discount_reason_code_id.present? ||
        obj.noncovered_reason_code_id.present? || obj.primary_payment_reason_code_id.present? ||
        obj.prepaid_reason_code_id.present? || obj.pr_reason_code_id.present? ||
        obj.miscellaneous_one_reason_code_id.present? || obj.miscellaneous_two_reason_code_id.present? ||

        obj.copay_hipaa_code_id.present? || obj.coinsurance_hipaa_code_id.present? ||
        obj.contractual_hipaa_code_id.present? || obj.deductible_hipaa_code_id.present? ||
        obj.denied_hipaa_code_id.present? || obj.discount_hipaa_code_id.present? ||
        obj.noncovered_hipaa_code_id.present? || obj.primary_payment_hipaa_code_id.present? ||
        obj.prepaid_hipaa_code_id.present? || obj.pr_hipaa_code_id.present? ||
        obj.miscellaneous_one_hipaa_code_id.present? || obj.miscellaneous_two_hipaa_code_id.present?
    end
    
    def set_adjustment_codes_and_reason_code_ids(object, is_multiple_reason_codes_applicable, attribute_to_set = nil)
      set_reason_code_ids(object, is_multiple_reason_codes_applicable)
      set_adjustment_codes_in_entity(object, is_multiple_reason_codes_applicable, attribute_to_set)
      object      
    end

    def set_reason_code_ids(object, is_multiple_reason_codes_applicable)
      coinsurance_id, contractual_id,copay_id, deductible_id, prepaid_id, patient_responsibility_id = [], [], [], [], [], []
      denied_id, discount_id, noncovered_id, primary_payment_id = [], [],[],[]
      miscellaneous_one_id, miscellaneous_two_id = [], []

      primary_reason_code_ids = {'noncovered' => object.noncovered_reason_code_id,
        'denied' => object.denied_reason_code_id,
        'discount' => object.discount_reason_code_id,
        'coinsurance' => object.coinsurance_reason_code_id,
        'deductible' => object.deductible_reason_code_id,
        'copay' => object.copay_reason_code_id,
        'primary_payment' => object.primary_payment_reason_code_id,
        'prepaid' => object.prepaid_reason_code_id,
        'patient_responsibility' => object.pr_reason_code_id,
        'contractual' => object.contractual_reason_code_id,
        'miscellaneous_one' => object.miscellaneous_one_reason_code_id,
        'miscellaneous_two' => object.miscellaneous_two_reason_code_id
      }.sort


      primary_reason_code_ids.each do |key, value|
        case key
        when 'coinsurance'
          coinsurance_id << value
        when 'contractual'
          contractual_id  << value
        when 'copay'
          copay_id  << value
        when 'deductible'
          deductible_id  << value
        when 'denied'
          denied_id  << value
        when 'discount'
          discount_id  << value
        when 'noncovered'
          noncovered_id  << value
        when 'primary_payment'
          primary_payment_id  << value
        when 'prepaid'
          prepaid_id  << value
        when 'patient_responsibility'
          patient_responsibility_id  << value
        when 'miscellaneous_one'
          miscellaneous_one_id  << value
        when 'miscellaneous_two'
          miscellaneous_two_id  << value
        end
      end

      if is_multiple_reason_codes_applicable
        if object.class == InsurancePaymentEob
          secondary_reason_code_ids_and_adjustment_reasons = object.insurance_payment_eobs_reason_codes.find(:all,
            :select => 'insurance_payment_eobs_reason_codes.adjustment_reason, insurance_payment_eobs_reason_codes.reason_code_id',
            :order => "insurance_payment_eobs_reason_codes.adjustment_reason ASC")
        else
          secondary_reason_code_ids_and_adjustment_reasons = object.service_payment_eobs_reason_codes.find(:all,
            :select => 'service_payment_eobs_reason_codes.adjustment_reason, service_payment_eobs_reason_codes.reason_code_id',
            :order => "service_payment_eobs_reason_codes.adjustment_reason ASC")
        end

        unless secondary_reason_code_ids_and_adjustment_reasons.blank?
          secondary_reason_code_ids_and_adjustment_reasons.each do |id_and_reason|
            case id_and_reason.adjustment_reason
            when 'coinsurance'
              coinsurance_id << id_and_reason.reason_code_id
            when 'contractual'
              contractual_id  << id_and_reason.reason_code_id
            when 'copay'
              copay_id  << id_and_reason.reason_code_id
            when 'deductible'
              deductible_id  << id_and_reason.reason_code_id
            when 'denied'
              denied_id  << id_and_reason.reason_code_id
            when 'discount'
              discount_id  << id_and_reason.reason_code_id
            when 'noncovered'
              noncovered_id  << id_and_reason.reason_code_id
            when 'primary_payment'
              primary_payment_id  << id_and_reason.reason_code_id
            when 'prepaid'
              prepaid_id  << id_and_reason.reason_code_id
            when 'patient_responsibility'
              patient_responsibility_id  << id_and_reason.reason_code_id
            when 'miscellaneous_one'
              miscellaneous_one_id  << id_and_reason.reason_code_id
            when 'miscellaneous_two'
              miscellaneous_two_id  << id_and_reason.reason_code_id
            end
          end
        end
      end

    end
  

    def set_adjustment_codes_in_entity(object, is_multiple_reason_codes_applicable, attribute_to_set = 'reason_code')
      attribute_to_set = 'unique_code'
      adjustment_reasons = ['coinsurance', 'contractual', 'copay', 'deductible', 'denied', 'discount',
        'miscellaneous_one', 'miscellaneous_two', 'noncovered', 'primary_payment', 'pr', 'prepaid']
      hipaa_code_ids_hash, reason_code_ids_hash, secondary_reason_code_hash = {}, {}, {}
      if is_multiple_reason_codes_applicable
        if object.class == InsurancePaymentEob
          secondary_reason_code_ids_and_adjustment_reasons = object.insurance_payment_eobs_reason_codes.find(:all,
            :select => 'insurance_payment_eobs_reason_codes.adjustment_reason, insurance_payment_eobs_reason_codes.reason_code_id',
            :order => "insurance_payment_eobs_reason_codes.adjustment_reason ASC")
        else
          secondary_reason_code_ids_and_adjustment_reasons = object.service_payment_eobs_reason_codes.find(:all,
            :select => 'service_payment_eobs_reason_codes.adjustment_reason, service_payment_eobs_reason_codes.reason_code_id',
            :order => "service_payment_eobs_reason_codes.adjustment_reason ASC")
        end
        if secondary_reason_code_ids_and_adjustment_reasons.present?
          secondary_reason_code_ids_and_adjustment_reasons.each do |record|
            if secondary_reason_code_hash[record.adjustment_reason].blank?
              secondary_reason_code_hash[record.adjustment_reason] = [record.reason_code_id]
            else
              secondary_reason_code_hash[record.adjustment_reason] << record.reason_code_id
            end
          end
        end
      end
      adjustment_reasons.each do |adjustment_reason|
        hipaa_code_ids_hash[adjustment_reason] = object.send("#{adjustment_reason}_hipaa_code_id")
        if reason_code_ids_hash[adjustment_reason].blank?
          reason_code_ids_hash[adjustment_reason] = [object.send("#{adjustment_reason}_reason_code_id")]
        else
          reason_code_ids_hash[adjustment_reason] << object.send("#{adjustment_reason}_reason_code_id")
        end
        if secondary_reason_code_hash.present? && secondary_reason_code_hash[adjustment_reason].present?
          reason_code_ids_hash[adjustment_reason] << secondary_reason_code_hash[adjustment_reason].flatten.compact.uniq          
        end
        reason_code_ids_hash[adjustment_reason] = reason_code_ids_hash[adjustment_reason].flatten.compact.uniq
      end
      
      hipaa_code_ids = hipaa_code_ids_hash.values.compact.uniq
      if hipaa_code_ids.present?
        hipaa_code_array_of_ids_and_codes_and_descriptions = HipaaCode.get_active_code_details_given_ids(hipaa_code_ids)
      end
      reason_code_ids = reason_code_ids_hash.values.flatten.compact.uniq
      reason_codes = ReasonCode.where(:id => reason_code_ids) if reason_code_ids.present?

      set_adjustment_codes_of_hipaa_codes(object, hipaa_code_array_of_ids_and_codes_and_descriptions, hipaa_code_ids_hash)
      set_adjustment_codes(object, reason_codes, reason_code_ids_hash, attribute_to_set)
    end

    def set_adjustment_codes(object, adjustment_code_records, adjustment_code_ids_hash, attribute_to_set)
      if adjustment_code_records && adjustment_code_records.length > 0 && adjustment_code_ids_hash.present?

        adjustment_code_ids_hash.each do |adjustment_reason, reason_code_ids|
          reason_code_ids.each do |reason_code_id|
            adjustment_code_records.each do |record|
              if reason_code_id == record.id
                if record.class == ReasonCode && !record.active && record.replacement_reason_code_id.present?
                  reason_code_record = record
                  replacement_reason_code_id = record.replacement_reason_code_id
                  if replacement_reason_code_id.present?
                    active_record = ReasonCode.find_active_record(record, replacement_reason_code_id)
                    reason_code_record = active_record if active_record.present?
                  end
                  record = reason_code_record
                end
                codes = object.send("#{adjustment_reason}_adjustment_codes")
                if codes.blank?
                  object.instance_variable_set("@#{adjustment_reason}_adjustment_codes", record.send(attribute_to_set))
                else
                  object.instance_variable_set("@#{adjustment_reason}_adjustment_codes",
                    codes + ';' + record.send(attribute_to_set))
                end
              end
            end
          end
        end
      end
    end

    def set_adjustment_codes_of_hipaa_codes(object, hipaa_code_array_of_ids_and_codes_and_descriptions, adjustment_code_ids_hash)
      if hipaa_code_array_of_ids_and_codes_and_descriptions.present?
        hipaa_code_array_of_ids_and_codes_and_descriptions.each do |id_and_code_and_description|
          hipaa_code_id = id_and_code_and_description[0]
          hipaa_adjustment_code = id_and_code_and_description[1]
          array_of_saved_codes_in_adjustment_reason = []
          hash_with_same_adjustment_code_ids_grouped_together = adjustment_code_ids_hash.group_by { |key, value| value.present? && ((value == hipaa_code_id) || value)}
          array_of_same_adjustment_code_ids = hash_with_same_adjustment_code_ids_grouped_together[true]

          if array_of_same_adjustment_code_ids
            array_of_same_adjustment_code_ids.each do |value|
              if value
                array_of_saved_codes_in_adjustment_reason << value[0]
              end
            end
          end

          array_of_saved_codes_in_adjustment_reason.each do |adjustment_reason|
            codes = object.send("#{adjustment_reason}_adjustment_codes")
            if codes.blank?
              object.send("#{adjustment_reason}_adjustment_codes=", hipaa_adjustment_code)
            else
              object.send("#{adjustment_reason}_adjustment_codes=",
                codes + ';' + hipaa_adjustment_code)
            end
          end

        end
      end
    end

    def set_crosswalked_codes_for_object(payer, object, client, facility)
      reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, object, client, facility)
      adjustment_reasons = ['coinsurance', 'contractual', 'copay', 'deductible', 'denied', 'discount',
        'miscellaneous_one', 'miscellaneous_two', 'noncovered', 'primary_payment', 'pr', 'prepaid']

      adjustment_reasons.each do |adjustment_reason|
        all_codes_array, reason_code_only_array = [], []
        crosswalk_codes = reason_code_crosswalk.get_all_codes(adjustment_reason)
        if crosswalk_codes.present?
          crosswalk_codes.each do |code_hash|
            # all_codes_array and element_string pass by reference
            build_array_of_codes(code_hash, all_codes_array, reason_code_only_array, facility)
          end
          all_codes_string = ""
          if all_codes_array.present?
            all_codes_string += all_codes_array.join(';')
          end
          if reason_code_only_array.present?
            all_codes_string += ';'
            all_codes_string += reason_code_only_array.join(';')
          end
          if all_codes_string.present?
            object.send("#{adjustment_reason}_crosswalked_codes=", all_codes_string)
          end
        end
        object
      end
    end

    def build_array_of_codes(code_hash, all_codes_array, reason_code_only_array, facility)
      elements = []
      # Happens when enable crosswalk is false
      crosswalk_code_is_reason_code = code_hash[:reason_code].present? && code_hash[:reason_code].to_s == code_hash[:cas_02].to_s
      if code_hash[:reason_code].present? && !crosswalk_code_is_reason_code
        elements << code_hash[:reason_code]
      end
      if code_hash[:cas_01].present? && code_hash[:cas_02].present?
        elements << code_hash[:cas_01] + code_hash[:cas_02]
      end
      lq_he_configs = facility.get_lqhe_configs
      if code_hash[:remark_codes].present? && lq_he_configs && lq_he_configs.include?('remark_code')
        elements << code_hash[:remark_codes].join(',')
      end
      if elements.present?
        element_string = elements.join(':')
        if code_hash[:cas_01].present? && code_hash[:cas_02].present?
          all_codes_array << element_string
        else
          reason_code_only_array << element_string
        end
      end
      all_codes_array
    end
   
  end
end