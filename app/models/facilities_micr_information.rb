class FacilitiesMicrInformation < ActiveRecord::Base
  belongs_to :facility
  belongs_to :micr_line_information
  belongs_to :client

  # client_id was not stored in DB data. So, client_id is not a mandatory to fetch the facility level.
  
  def self.get_onbase_name_record_for_particular_level(micr_id, client_id = nil, facility_id = nil)
    if !micr_id.blank?
      condition = "onbase_name IS NOT NULL AND micr_line_information_id = #{micr_id}"
      if !facility_id.blank?
        condition += " AND facility_id = #{facility_id}"
      elsif !client_id.blank? && facility_id.blank?
        condition += " AND client_id = #{client_id} AND facility_id IS NULL"
      end
      self.select('onbase_name').where(condition).limit(1).first
    end
  end

  def self.get_client_or_site_specific_onbase_name_record(micr_id, client_id = nil, facility_id = nil)
    priority_record = nil
    onbase_name_records = self.get_onbase_name_record_for_all_levels(micr_id)
    onbase_name_records.each do |onbase_name_record|
      if !micr_id.blank? && !facility_id.blank? &&
          onbase_name_record.micr_line_information_id == micr_id.to_i &&
          onbase_name_record.facility_id == facility_id.to_i
        priority_record = onbase_name_record
        break
      end
    end
    if priority_record.blank?
      onbase_name_records.each do |onbase_name_record|
        if !micr_id.blank? && !client_id.blank? && onbase_name_record.facility_id.blank? &&
            onbase_name_record.micr_line_information_id == micr_id.to_i && onbase_name_record.client_id == client_id.to_i
          priority_record = onbase_name_record
          break
        end
      end
    end
    priority_record
  end

  def self.get_onbase_name_record_for_all_levels(micr_id)
    self.select("facilities_micr_informations.id, facilities_micr_informations.onbase_name,
      facilities_micr_informations.micr_line_information_id,
      clients.name AS client_name, clients.id AS client_id,
      facilities.name AS facility_name, facilities.id AS facility_id").
      where("onbase_name IS NOT NULL AND micr_line_information_id = #{micr_id}").
      joins("LEFT OUTER JOIN clients ON clients.id = facilities_micr_informations.client_id
      LEFT OUTER JOIN facilities ON facilities.id = facilities_micr_informations.facility_id")
  end

  def self.initialize_or_update_if_found(micr_id, client_id, facility_id, new_onbase_name)
    existing_record = get_onbase_name_record_for_particular_level(micr_id, client_id, facility_id)
    if !existing_record.blank?
      if existing_record.onbase_name != new_onbase_name
        existing_record.onbase_name = new_onbase_name
        existing_record.save
      end
    else
      new_record = self.new(:micr_line_information_id => micr_id,
        :client_id => client_id, :facility_id => facility_id, :onbase_name => new_onbase_name)
    end
    new_record
  end

end
