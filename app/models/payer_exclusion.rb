class PayerExclusion < ActiveRecord::Base
  belongs_to :payer
  belongs_to :micr_line_information
  belongs_to :facility
  validates_presence_of :facility_id
  validates_uniqueness_of :facility_id, :scope => :payer_id
  validate :either_payer_or_micr_present

  def either_payer_or_micr_present
    if not (payer || micr_line_information)
      missing_entity = payer.blank? ? payer.class : micr_line_information.class
      errors[:base] << "Payer Exlusion Record must have a Payer or MICR. #{missing_entity} is missing."
    end
  end
end
