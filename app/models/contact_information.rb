class ContactInformation < ActiveRecord::Base
  has_many :insurance_payment_eobs
  has_many :payers
  
  validates_uniqueness_of :address_line_one, 
    :scope => [:address_line_two, :city, :state, :zip, :entity]

  # Calculating processor_input_field_count.
  def processor_input_field_count
    constant_fields_with_data = []
    constant_fields = [address_line_one, address_line_two, city, state, zip]
    constant_fields_with_data = constant_fields.select{|field| !field.blank?}
    constant_fields_with_data.length
  end
end
