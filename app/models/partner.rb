class Partner < ActiveRecord::Base
  
  has_many :config_settings
  has_many :clients, :dependent => :destroy
    
  def self.all_facilities
    Facility.find(:all,:select=>"concat(clients.name, ' - ',facilities.name) as cname,facilities.id",
        :joins =>'inner join clients on clients.id = facilities.client_id inner join partners on clients.partner_id = partners.id',
        :order=>'clients.name, facilities.name')
  end

  def self.is_partner_bac?
    self.where("name='BAC'").exists?
  end
  
end
