class FacilitiesNpiAndTin < ActiveRecord::Base
  belongs_to :facility
  belongs_to :upmc_facility
end
