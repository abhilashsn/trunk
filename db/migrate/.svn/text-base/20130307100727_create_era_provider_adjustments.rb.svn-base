class CreateEraProviderAdjustments < ActiveRecord::Migration
  def change
    create_table :era_provider_adjustments do |t|
      t.references :era_check, :null => false
      t.string :provider_identifier, :limit => 50, :null => false
      t.date :fiscal_period_date, :null => false
      t.string :provider_adjustment_reason_code1, :limit => 2, :null => false
      t.string :provider_adjustment_identifier1, :limit => 50
      t.decimal :provider_adjustment_amount1, :precision => 18, :scale => 2, :null => false

      t.timestamps
    end
    add_index :era_provider_adjustments, :era_check_id
  end
end
