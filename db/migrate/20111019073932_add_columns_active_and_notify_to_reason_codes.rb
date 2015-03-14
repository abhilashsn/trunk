class AddColumnsActiveAndNotifyToReasonCodes < ActiveRecord::Migration
 def self.up
    add_column :reason_codes, :active, :boolean, :default => true
    add_column :reason_codes, :notify, :boolean, :default => false
  end

  def self.down
    remove_column :reason_codes, :active
    remove_column :reason_codes, :notify
  end
end
