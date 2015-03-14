class FacilityCutRelationship < ActiveRecord::Base
  belongs_to :facility
  has_many :inbound_file_informations
end
