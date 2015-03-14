class ClientCode < ActiveRecord::Base
  has_many :reason_codes_clients_facilities_set_names_client_codes
  has_many :reason_codes_clients_facilities_set_names, :through => :reason_codes_clients_facilities_set_names_client_codes
  validates_presence_of :adjustment_code
  validates_uniqueness_of :adjustment_code

  def self.map_client_code(client_code)
    self.find_by_adjustment_code(client_code)
  end

  def qualified_for_deletion?
    self.reason_codes_clients_facilities_set_names_client_codes.length == 0
  end

end
