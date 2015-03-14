module Unified835Output

  def self.find_class facility, class_type, facility_config = nil
      client_name = facility.client.name.downcase.gsub("'", "")
      class_name(facility.name.to_file, class_type) || class_name(client_name.to_file, class_type) || "Unified835Output::Generator".constantize
  end

  def self.class_name type, class_type
    type = type.camelize
    if class_type == "single"
      "Unified835Output::#{type}SingleStGenerator".constantize  rescue nil
    else
      "Unified835Output::#{type}Generator".constantize  rescue nil
    end
  end

end