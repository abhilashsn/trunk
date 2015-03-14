module EdiHelper
  module ClassMethods
  end
  
  module InstanceMethods
    def composite_element(components, subelement_delimiter = '<')
      return components.reject {|x| x.blank?}.join(subelement_delimiter)
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end