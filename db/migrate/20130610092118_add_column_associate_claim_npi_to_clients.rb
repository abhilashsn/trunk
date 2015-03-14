class AddColumnAssociateClaimNpiToClients < ActiveRecord::Migration
  def change
    add_column :clients, :associate_claim_npi, :boolean, :default => 0
  end
end
