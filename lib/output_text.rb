# To change this template, choose Tools | Templates
# and open the template in the editor.

module OutputText
require 'logger'
#Checksif there's a custom class to be applied for a given organization
  #organization can be facility/client/partner
  #searches for custom class in that order.
  #Where there's no custom class, returns the base class
  def self.class_for(type,organization = nil)
    detect_class(type, organization) ||
      detect_class(type, organization.client) ||
      detect_class(type,organization.client.partner) ||
      "OutputText::#{type}".constantize
  end

  def self.detect_class(type, organization)
    "OutputText::#{name_for(type,organization)}".constantize if organization rescue nil
  end
  #Takes in the facility/client/partner name and the type of 835 subclass
  #and returns the name of the custom class for that organization
  #ex: organization = 'HLSC' and Type = 'Check'
  #returns 'HlscCheck'
  def self.name_for(type,organization)
    custom_class_for_facility = organization.name.downcase.gsub(' ','_').classify if organization
    "#{custom_class_for_facility}#{type}"
  end
  
   def self.log
    Logger.new('output_logs/TextGeneration.log', 'daily')
  end
end
