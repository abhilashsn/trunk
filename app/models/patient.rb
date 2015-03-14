class Patient < ActiveRecord::Base
  include DcGrid
  belongs_to :insurance_payment_eob

  after_update :create_qa_edit
  before_save :upcase_grid_data

  def create_qa_edit
    QaEdit.create_records(self)
  end
  
  def name
    first_name + ' ' + last_name
  end
  
  # Calculating processor_input_field_count for patients
  def processor_input_field_count
    constant_fields = [address_one, address_two, zip_code, city, state]
    constant_fields_with_data = constant_fields.select{|field| !field.blank?}
    total_field_count_with_data = constant_fields_with_data.length
    total_field_count_with_data
  end
end
