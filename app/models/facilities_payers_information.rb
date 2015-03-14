class FacilitiesPayersInformation < ActiveRecord::Base
  belongs_to :facility
  belongs_to :payer
  belongs_to :client

  # client_id was not stored in DB data. So, client_id is not a mandatory to fetch the facility level.

  def self.find_record_of_particular_level(payer_id, client_id = nil, facility_id = nil)
    if !payer_id.blank?
      condition = "payer_id = #{payer_id}"
      if !facility_id.blank?
        condition += " AND facility_id = #{facility_id}"
      elsif !client_id.blank? && facility_id.blank?
        condition += " AND client_id = #{client_id} AND facility_id IS NULL"
      end

      self.where(condition).limit(1).first
    end
  end
  
  def self.get_output_payid_record_for_particular_level(payer_id, client_id = nil, facility_id = nil)
    if !payer_id.blank?
      condition = "output_payid IS NOT NULL AND payer_id = #{payer_id}"
      if !facility_id.blank?
        condition += " AND facility_id = #{facility_id}"
      elsif !client_id.blank? && facility_id.blank?
        condition += " AND client_id = #{client_id} AND facility_id IS NULL"
      end
      self.select('output_payid').where(condition).limit(1).first
    end
  end

  def self.get_client_or_site_specific_output_payid_record(payer_id, client_id = nil, facility_id = nil)
    priority_record = nil
    output_payid_records = self.get_output_payid_record_for_all_levels(payer_id)
    output_payid_records.each do |output_payid_record|
      if !payer_id.blank? && !facility_id.blank? && output_payid_record.payer_id == payer_id.to_i &&
          output_payid_record.facility_id == facility_id.to_i
        priority_record = output_payid_record
        break
      end
    end

    if priority_record.blank?
      output_payid_records.each do |output_payid_record|
        if !payer_id.blank? && !client_id.blank? && output_payid_record.facility_id.blank? &&
            output_payid_record.payer_id == payer_id.to_i && output_payid_record.client_id == client_id.to_i
          priority_record = output_payid_record
          break
        end
      end
    end

    priority_record
  end

  def self.get_output_payid_record_for_all_levels(payer_id)
    self.select("facilities_payers_informations.id , 
      facilities_payers_informations.output_payid, facilities_payers_informations.payer_id,
      clients.name AS client_name, clients.id AS client_id,
      facilities.name AS facility_name, facilities.id AS facility_id").
      where("output_payid IS NOT NULL AND payer_id = #{payer_id}").
      joins("LEFT OUTER JOIN clients ON clients.id = facilities_payers_informations.client_id
      LEFT OUTER JOIN facilities ON facilities.id = facilities_payers_informations.facility_id")
  end

  def self.get_blank_output_payid_record_for_all_levels(payer_id)
    self.select("facilities_payers_informations.id ,
      facilities_payers_informations.output_payid, facilities_payers_informations.payer_id,
      clients.name AS client_name, clients.id AS client_id,
      facilities.id AS facility_id, payers.payer_type AS payer_type").
      where(["(output_payid IS NULL OR output_payid = '') AND facility_id IS NULL AND
      payer_id = ? AND payers.payer_type != ? ", payer_id, 'PatPay']).
      joins("LEFT OUTER JOIN clients ON clients.id = facilities_payers_informations.client_id
      LEFT OUTER JOIN facilities ON facilities.id = facilities_payers_informations.facility_id
      LEFT OUTER JOIN payers ON payers.id = facilities_payers_informations.payer_id")
  end

  def self.get_payer_specific_records(payer_id)
    self.select("facilities_payers_informations.id ,
      facilities_payers_informations.output_payid, facilities_payers_informations.payer_id,
      clients.name AS client_name, clients.id AS client_id,
      facilities.id AS facility_id, payers.payer_type AS payer_type").
      where(["facility_id IS NULL AND payer_id = ? AND payers.payer_type != ? ", payer_id, 'PatPay']).
      joins("LEFT OUTER JOIN clients ON clients.id = facilities_payers_informations.client_id
      LEFT OUTER JOIN facilities ON facilities.id = facilities_payers_informations.facility_id
      LEFT OUTER JOIN payers ON payers.id = facilities_payers_informations.payer_id")
  end

  def self.initialize_or_update_if_found(payer_id, client_id, facility_id, new_output_payid)
    existing_record = find_record_of_particular_level(payer_id, client_id, facility_id)
    if !existing_record.blank?
      if existing_record.output_payid != new_output_payid
        existing_record.output_payid = new_output_payid
        existing_record.client_id = client_id if existing_record.client_id.blank?
        existing_record.save
      end
    else
      new_record = self.new(:payer_id => payer_id,
        :client_id => client_id, :facility_id => facility_id, :output_payid => new_output_payid)
    end
    new_record
  end

end
