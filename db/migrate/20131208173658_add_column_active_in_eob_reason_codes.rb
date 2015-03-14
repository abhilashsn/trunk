class AddColumnActiveInEobReasonCodes < ActiveRecord::Migration
  def change
     add_column :eob_reason_codes, :active, :boolean, :default => true
  end
end
