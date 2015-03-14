class CreateDefaultCodesForAdjustmentReasons < ActiveRecord::Migration
  def up
    create_table :default_codes_for_adjustment_reasons do |t|
      t.column :adjustment_reason, :string, :limit => 20
      t.column :group_code, :string, :limit => 45
      t.column :facility_id, :integer, :limit => 11
      t.column :hipaa_code_id, :integer, :limit => 11
      t.timestamps
    end
  end

  def down
    drop_table :default_codes_for_adjustment_reasons
  end
end
