class RemoveIndexOnCheckNumberdInReasonCodes < ActiveRecord::Migration
  def change
    remove_index :reason_codes, :name => 'idx_reason_check_number' if index_exists?(:reason_codes, :check_number, :name => "idx_reason_check_number")
    remove_index :reason_codes, :name => 'by_check_number'
  end
end
