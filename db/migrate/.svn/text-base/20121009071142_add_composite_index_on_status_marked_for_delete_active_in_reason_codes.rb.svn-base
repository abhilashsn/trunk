class AddCompositeIndexOnStatusMarkedForDeleteActiveInReasonCodes < ActiveRecord::Migration
  def change
    add_index(:reason_codes, [:STATUS, :marked_for_deletion, :active], :name => "index_on_status_marked_for_deletion_active")
  end
end