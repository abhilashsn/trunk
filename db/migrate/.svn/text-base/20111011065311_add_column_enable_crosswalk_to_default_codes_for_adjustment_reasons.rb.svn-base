class AddColumnEnableCrosswalkToDefaultCodesForAdjustmentReasons < ActiveRecord::Migration
  def self.up
    add_column :default_codes_for_adjustment_reasons, :enable_crosswalk, :boolean, :default => true
  end

  def self.down
    remove_column :default_codes_for_adjustment_reasons, :enable_crosswalk
  end
end
