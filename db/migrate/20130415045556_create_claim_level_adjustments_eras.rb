class CreateClaimLevelAdjustmentsEras < ActiveRecord::Migration
  def change
    create_table :claim_level_adjustments_eras do |t|
      t.references :insurance_payment_era
      t.string :cas_group_code, :limit => 2
      t.string :cas_hipaa_code, :limit => 5
      t.decimal :adjustment_amount, :precision => 18, :scale => 2
      t.column :adjustment_quantity, :bigint
      t.timestamps
    end
  end
end

