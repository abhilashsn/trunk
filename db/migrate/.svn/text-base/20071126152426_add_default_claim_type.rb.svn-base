class AddDefaultClaimType < ActiveRecord::Migration
  def up
    cliam_type = ["Primary","Secondary",
      "Denial", "Primary-FAP"]

    cliam_type.each do |vl|
      execute "INSERT INTO claim_types(claim_type) VALUES('#{vl}')"
    end
  end

  def down
    ClaimType.delete_all
  end
end
