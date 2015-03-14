# This model is to track the deleted records of batch, job, check_information,
#  insurance_payment_eob, patient_pay_eob, service_payment_eob.
# There is a unified database containing data across all the instances of cleints or facilities.
# The records that gets deleted from a particular instance has to be reflected in the unified database.
# Thus this table data is used to delete the from the unified database,
#   corresponding to the records from the instance specific databse .
# No associations kept so far in the application

class DeletedEntity < ActiveRecord::Base  

  def self.create_records(parameters, to_save = false)
    if parameters.present?
      record = DeletedEntity.new(:entity => parameters[:entity],
        :entity_id => parameters[:entity_id], :client_id => parameters[:client_id],
        :facility_id => parameters[:facility_id], :created_at => Time.now)
      if to_save
        record.save
      else
        record
      end
    end
  end

end