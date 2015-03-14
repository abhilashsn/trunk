class Era < ActiveRecord::Base

    has_many :era_checks
    has_many :era_jobs
    has_many :misc_segments_eras
    has_many :era_exceptions
    belongs_to :inbound_file_information

end
