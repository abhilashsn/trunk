class SetActiveIndicatorToTrueByDefaultInReasonCodesClientsFacilitiesSetNames < ActiveRecord::Migration
  def up
    change_column :reason_codes_clients_facilities_set_names, :active_indicator, :boolean, :default => 1
  end
  
  def down
    change_column :reason_codes_clients_facilities_set_names, :active_indicator, :boolean
  end
end
