#Holds all service line level customizations for Client A of HLSC
class Output835::ClientAService < Output835::HlscService

  def service_supplemental_amount
  end

  # Returns the custom group code for this lockbox
  # by taking in the dollar amount field name in db
  def group_code(amount_column)
    case amount_column	
    when 'service_discount'
      'PI'
    when 'denied' 
      'OA'
    when 'service_no_covered'
      'OA'
    end
  end
  # To override reason codes with custom reason codes for Client A
  def code(amount_column)
    if amount_column == 'service_discount'
      "137"
    end
  end
end