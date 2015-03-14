module ArchiveHelper

 
  def highlight_color_for_fields_in_service_lines(field_name, service_line_id)
    highlight_color = ''
    if current_user.has_role?(:processor) && params[:from] == 'processor_reports'
      qa_edit = QaEdit.find_by_service_payment_eob_id_and_field_name(service_line_id, field_name)
      if !qa_edit.blank?
        highlight_color = 'edited'
        highlight_color = '' if (qa_edit.previous_value.blank? && qa_edit.current_value.blank?)
      end
    end
    highlight_color
  end

  def highlight_color_for_fields_in_insurance_eobs(field_name, eob_id)
    highlight_color = ''
    if current_user.has_role?(:processor) && params[:from] == 'processor_reports'
      qa_edit = QaEdit.find_by_insurance_payment_eob_id_and_field_name(eob_id, field_name)
      if !qa_edit.blank?        
        highlight_color = 'edited'
        highlight_color = '' if (qa_edit.previous_value.blank? && qa_edit.current_value.blank?)
      end
    end
    highlight_color
  end

  def highlight_color_for_fields_in_claim_level_insurance_eobs(field_name, eob_id, category)
    highlight_color = ''
    if current_user.has_role?(:processor) && params[:from] == 'processor_reports' && category == "claim"
      qa_edit = QaEdit.find_by_insurance_payment_eob_id_and_field_name(eob_id, field_name)
      if !qa_edit.blank?
        highlight_color = 'edited'
        highlight_color = '' if (qa_edit.previous_value.blank? && qa_edit.current_value.blank?)
      end
    end
    highlight_color
  end

  def highlight_color_for_fields_in_nextgen_eobs(field_name, eob_id)
    highlight_color = ''
    if current_user.has_role?(:processor) && params[:from] == 'processor_reports'
      qa_edit = QaEdit.find_by_patient_pay_eob_id_and_field_name(eob_id, field_name)
      if !qa_edit.blank?
        highlight_color = 'edited'
        highlight_color = '' if (qa_edit.previous_value.blank? && qa_edit.current_value.blank?)
      end
    end
    highlight_color
  end

  def display_values(activity_record)
    object_name = activity_record.object_name
    field_name = activity_record.field_name
    old_value = activity_record.old_value
    new_value = activity_record.new_value
    model_name = object_name.classify.constantize
    case field_name
    when 'reason_code_set_name_id'
      if old_value.present? && new_value.present?
        result_objects = ReasonCodeSetName.where("id IN (#{old_value}, #{new_value})")

        if result_objects.present?
          normalized_field_name = 'reason_code_set_name'
          if result_objects[0].present? && result_objects[1].present? && result_objects[0].id == old_value.to_i && result_objects[1].id == new_value.to_i
            normalized_old_value = result_objects[0].name
            normalized_new_value = result_objects[1].name
          elsif result_objects[0].present? && result_objects[1].blank? && result_objects[0].id == old_value.to_i
            normalized_old_value = result_objects[0].name
          elsif result_objects[0].present? && result_objects[1].blank? && result_objects[0].id == new_value.to_i
            normalized_new_value = result_objects[0].name
          end
        end
      end
    else
      normalized_field_name = field_name
      normalized_old_value = old_value
      normalized_new_value = new_value
    end
    return normalized_field_name, normalized_old_value, normalized_new_value
  end

  def activity_performed_on_user(activity_record)
    if activity_record.processorname.present?
      activity_user = activity_record.processorname
    elsif activity_record.qa_name.present?
      activity_user = activity_record.qa_name
    end
    "User #{activity_user}" if activity_user.present?
  end

  def display_activity_record(activity_record)
    field_name, old_value, new_value = display_values(activity_record)    
    performed_on_user = activity_performed_on_user(activity_record)
    activity = activity_record.activity
    activity_field_name_conjuction = 'of'
    activity_field_name = field_name.gsub('_', ' ') if field_name.present?
    old_value_conjuction = 'from'
    new_value_conjuction = 'to'
    activity_user_conjuction = 'by'
    activity_user = activity_record.allocater_name

    deallocation_record = ((activity_record.activity == 'Processor De-Allocated' || activity_record.activity == 'QA De-Allocated') && field_name == 'check_number')
  
    activity_statement = []
    activity_statement << performed_on_user if performed_on_user.present?
    activity_statement << activity if activity.present?
    if deallocation_record
      activity_statement << 'from'
    else
      activity_statement << activity_field_name_conjuction if activity_field_name.present?
    end
    activity_statement << activity_field_name if activity_field_name.present?
    if deallocation_record
      activity_statement << 'of'
    else
      activity_statement << old_value_conjuction if old_value.present? && activity != 'Images Are Removed'
    end
    activity_statement << "'#{old_value}'" if old_value.present?
    activity_statement << new_value_conjuction if new_value.present? && activity != 'Images Are Added'
    activity_statement << "'#{new_value}'" if new_value.present?
    activity_statement << activity_user_conjuction if activity_user_conjuction.present?
    activity_statement << activity_user if activity_user.present?
    activity_statement.join(' ')
  end


end
