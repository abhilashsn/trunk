class CreateArchivedClaimInformations < ActiveRecord::Migration
  def up
    create_table :archived_claim_informations do |t|
      t.column :patient_first_name, :string ,:limit =>35
      t.column :patient_last_name, :string ,:limit =>30
      t.column :patient_middle_initial, :string ,:limit =>20
      t.column :patient_suffix, :string ,:limit =>20
      t.column :patient_account_number, :string ,:limit =>40
      t.column :insured_id,:string
      t.column :total_charges,:decimal,:precision => 10, :scale => 2
      t.column :provider_ein,:string,:limit =>15
      t.column :facility_id,:integer
      t.column :provider_last_name,:string,:limit =>28
      t.column :provider_suffix,:string,:limit =>20
      t.column :provider_first_name,:string,:limit =>28
      t.column :provider_middle_initial,:string,:limit =>28
      t.column :provider_npi,:string,:limit =>15
      t.column :billing_provider_organization_name,:string
      t.column :payer_name,:string
      t.column :payer_address,:string
      t.column :payer_city,:string
      t.column :payer_state,:string,:limit =>3
      t.column :payer_zipcode,:string
      t.column :subscriber_first_name, :string ,:limit =>35
      t.column :subscriber_last_name, :string ,:limit =>30
      t.column :subscriber_middle_initial, :string ,:limit =>20
      t.column :subscriber_suffix, :string ,:limit =>20
      t.column :drg_code,:string,:limit=>6
      t.column :plan_type,:string,:limit=>20
      t.column :facility_type_code, :string
      t.column :policy_number, :string
      t.column :claim_type,  :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def down
    drop_table :archived_claim_informations
  end
  def connection
    ClaimInformation.connection
  end
end
