class Crosswalk < ActiveRecord::Base
  belongs_to :client
  belongs_to :facility
  belongs_to :payer
end
