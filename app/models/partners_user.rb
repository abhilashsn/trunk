class PartnersUser < ActiveRecord::Base

	belongs_to :partner
	belongs_to :client

end
