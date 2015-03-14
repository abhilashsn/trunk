# Check level output customizations for Client A
class Output835::ClientACheck < Output835::HlscCheck
  # Reports adjustments to the actual payment that are NOT
  # specific to a particular claim or service
  # These adjustments can either decrease the payment (a positive
  # number) or increase the payment (a negative number)
  # such as the remainder of check amount subtracted by total eob payemnts (provider adjustment)
  # or interest amounts of eobs etc.
  def provider_adjustment
    if check.provider_adjustment_amount
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << federal_tax_id || '999999999'
      provider_adjustment_elements << year_end_date
      provider_adjustment_elements << check.provider_adjustment_qualifier
      provider_adjustment_elements << check.provider_adjustment_amount
      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
  end
end