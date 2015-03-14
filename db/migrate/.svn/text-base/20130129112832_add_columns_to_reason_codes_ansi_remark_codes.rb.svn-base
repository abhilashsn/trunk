class AddColumnsToReasonCodesAnsiRemarkCodes < ActiveRecord::Migration
  def change
    add_column :reason_codes_ansi_remark_codes, :client_id, :integer
    add_column :reason_codes_ansi_remark_codes, :active_indicator, :boolean, :default => true

    add_index :reason_codes_ansi_remark_codes, :client_id, :name => "index_client_id"
  end
end
