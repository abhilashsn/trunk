class QaEditsController < ApplicationController

  def list
    if params[:eob_type] == 'insurance'
      @qa_edit_records = QaEdit.find_all_by_insurance_payment_eob_id(params[:eob_id])
    elsif params[:eob_type] == 'nextgen'
      @qa_edit_records = QaEdit.find_all_by_patient_pay_eob_id(params[:eob_id])
    end

    # The following is to remove some of the flaot values that gets saved as
    # nil to zero and then from zero to nil in one transaction of EOB in qa_edits
    @qa_edits = []
    indexes_to_delete = []
    field_name_hash = {}
    @qa_edit_records.each_with_index do | qa_edit, index|
      if !['qa_id', 'payer_id'].include?(qa_edit.field_name)
        if qa_edit.field_name == 'subscriber_identification_code'
          qa_edit.field_name = 'member_id'
        end            
        @qa_edits << qa_edit
      end          
      field_name_hash[qa_edit.field_name.to_sym] = {} if field_name_hash[qa_edit.field_name.to_sym].blank?
      if field_name_hash[qa_edit.field_name.to_sym][:previous_values].blank?
        field_name_hash[qa_edit.field_name.to_sym][:previous_values]  = [qa_edit.previous_value]
      else
        field_name_hash[qa_edit.field_name.to_sym][:previous_values] << qa_edit.previous_value
      end
      if field_name_hash[qa_edit.field_name.to_sym][:indexes].blank?
        field_name_hash[qa_edit.field_name.to_sym][:indexes]  = [index]
      else
        field_name_hash[qa_edit.field_name.to_sym][:indexes] << index
      end
    end
    @qa_edits.each do |qa_edit|
      first_index = nil
      second_index = nil
      if !field_name_hash[qa_edit.field_name.to_sym].blank?
        previous_values_array = field_name_hash[qa_edit.field_name.to_sym][:previous_values]
        if previous_values_array.length > 1
          previous_values_array.each_with_index do |previous_value, index|
            if previous_value.nil?
              first_index = index
              break;
            end
          end
        end
        index_array = field_name_hash[qa_edit.field_name.to_sym][:indexes]
        if !index_array.blank? && !first_index.blank?
          second_index = first_index + 1
          if !second_index.blank?
            first_index = index_array[first_index]
            second_index = index_array[second_index]
            first_qa_edit_element = @qa_edits[first_index]
            second_qa_edit_element = @qa_edits[second_index]
            if first_index != second_index && !first_qa_edit_element.blank?  && !second_qa_edit_element.blank?
              if (first_qa_edit_element.previous_value.nil? && first_qa_edit_element.current_value.to_f.zero?) &&
                  (second_qa_edit_element.previous_value.to_f.zero? && second_qa_edit_element.current_value.nil?)
                indexes_to_delete << first_index << second_index
              end
            end
          end
        end
      end
    end
    if !indexes_to_delete.blank?
      @qa_edits.delete_at(indexes_to_delete[0])
      indexes_to_delete.delete_at(0)
      indexes_to_delete.each do | index |
        @qa_edits.delete_at(index - 1)
      end
    end
  end
  
end
