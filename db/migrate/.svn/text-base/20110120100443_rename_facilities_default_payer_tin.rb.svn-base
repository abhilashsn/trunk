class RenameFacilitiesDefaultPayerTin < ActiveRecord::Migration
  def up
    rename_column :facilities, :default_payer_tin, :default_insurance_payer_tin
  end

  def down
    rename_column :facilities, :default_insurance_payer_tin, :default_payer_tin 
  end
end
