class AddReasonCodeSetNameIdAndClientIdToErrorPopups < ActiveRecord::Migration
  def change
    add_column :error_popups, :reason_code_set_name_id, :integer
    add_column :error_popups, :client_id, :integer
  end
end
