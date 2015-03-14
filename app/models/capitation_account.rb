class CapitationAccount < ActiveRecord::Base
  include DcGrid
# Relationship for capitation account details report
  belongs_to :batch
  belongs_to :user

# Validation of the Capitation Account Report 
  validates_presence_of :patient_first_name
  validates_presence_of :patient_last_name
  validates_presence_of :account
  validates_presence_of :payment
  validates_presence_of :checknumber

  before_save :upcase_grid_data
  
end
