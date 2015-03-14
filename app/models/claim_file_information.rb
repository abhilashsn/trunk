class ClaimFileInformation < ActiveRecord::Base
  require 'csv'

  has_many :claim_informations
  belongs_to :facility
  belongs_to :output_activity_log
  belongs_to :inbound_file_information

end
