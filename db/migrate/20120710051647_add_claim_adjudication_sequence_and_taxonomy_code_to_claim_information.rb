class AddClaimAdjudicationSequenceAndTaxonomyCodeToClaimInformation < ActiveRecord::Migration
  def change
    add_column :claim_informations, :claim_adjudication_sequence, :string
    add_column :claim_informations, :taxonomy_code, :string
  end
  def connection
    ClaimInformation.connection
  end
end
