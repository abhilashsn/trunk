class CreateAssociationBetweenClientAndPartner < ActiveRecord::Migration
  def up    
    partner_id = Partner.find_by_name("REVENUE MED").id
    clients = Client.all
    clients.each do |client| 
      client.partner_id = partner_id
      client.save!
    end    
  end

  def down
  end
end