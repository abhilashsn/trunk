class CreateArchivedClaimServiceInformations < ActiveRecord::Migration
  def up
    create_table :archived_claim_service_informations do |t|
      t.column :archived_claim_informations_id, :integer,:references=>:archived_claim_informations
      t.column :service_from_date, :date
      t.column :service_to_date, :date
      t.column :days_units,:decimal,:precision => 10, :scale => 2
      t.column :cpt_hcpcts, :string ,:limit =>20
      t.column :charges, :decimal,:precision => 10, :scale => 2
      t.column :modifier1, :string,:limit =>2
      t.column :modifier2, :string,:limit =>2
      t.column :modifier3, :string,:limit =>2
      t.column :modifier4, :string,:limit =>2
      t.column :quantity, :decimal,:precision => 8, :scale => 2
      t.column :non_covered_charge, :decimal,:precision => 8, :scale => 2
      t.column :revenue_code, :string,:limit =>6
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    execute "ALTER TABLE archived_claim_service_informations
               ADD CONSTRAINT archived_claim_service_informations_idfk_1 FOREIGN KEY (archived_claim_informations_id)
            REFERENCES archived_claim_informations(id)"
  end

  def down
    execute "ALTER TABLE archived_claim_service_informations DROP FOREIGN KEY archived_claim_service_informations_idfk_1"
    drop_table :archived_claim_service_informations
  end
  def connection
    ClaimInformation.connection
  end
  def connection
    ClaimServiceInformation.connection
  end
end
