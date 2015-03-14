class ReportCheckInformation < ActiveRecord::Base
  belongs_to :job
  belongs_to :batch
  belongs_to :check_information
end
