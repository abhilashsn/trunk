class BusinessUnitIndicatorLookupField < ActiveRecord::Base

  def self.business_indicator(claim_id)
    business_unit_indicator = ClaimInformation.find(claim_id).business_unit_indicator
    return  self.find_by_business_unit_indicator(business_unit_indicator).financial_class if business_unit_indicator
  end
end
