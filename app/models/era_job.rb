class EraJob < ActiveRecord::Base
  belongs_to :era
  belongs_to :era_check
  belongs_to :client

  def self.map_site(facility, era_job)
    era_jobs = EraJob.where(:payee_name => era_job.payee_name, :payee_npi => era_job.payee_npi, :payee_tin => era_job.payee_tin)
    FacilityAlias.find_or_create_by_name_and_facility_id(era_job.payee_name, facility.id)

    era_jobs.each do |ej|
      ej.update_attributes(:facility_id => facility.id, :status => "MAPPED")

      if ej.era_check.exception_status == "Both"
        ej.era_check.update_attributes(:exception_status => "Unidentified Payer")
      else
        ej.era_check.update_attributes(:exception_status => nil)
      end 
    end
  end

end
