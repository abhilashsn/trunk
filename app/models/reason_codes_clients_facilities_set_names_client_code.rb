class ReasonCodesClientsFacilitiesSetNamesClientCode < ActiveRecord::Base
  belongs_to :reason_codes_clients_facilities_set_name
  belongs_to :client_code
  belongs_to :denied_client_code, :class_name => 'ClientCode',
    :foreign_key => 'client_code_id', :conditions => ['category = ?', "DENIED"]
end
