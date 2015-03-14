class UpmcFacility < ActiveRecord::Base
  belongs_to :facility, :foreign_key => 'lockbox_id'
  has_many :facility_aliases, :foreign_key => 'facility_id'
  has_many :facilities_npi_and_tins

  def lockbox
    self.facility
  end
end
