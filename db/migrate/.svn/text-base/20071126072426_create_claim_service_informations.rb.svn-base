class CreateClaimServiceInformations < ActiveRecord::Migration
  def up
    create_table :claim_service_informations do |t|
      t.column :claim_informations_id, :integer,:references=>:claim_informations
      t.column :service_from_date, :date
      t.column :service_to_date, :date
      t.column :days_units,:decimal,:precision => 10, :scale => 2
      t.column :cpt_hcpcts, :string ,:limit =>20
    end
  end

  def down
    drop_table :claim_service_informations
  end
  def connection
    ClaimInformation.connection
  end
  def connection
    ClaimServiceInformation.connection
  end
end
