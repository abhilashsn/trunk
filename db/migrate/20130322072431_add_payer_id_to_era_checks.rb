class AddPayerIdToEraChecks < ActiveRecord::Migration
  def change
    add_column :era_checks, :payer_id, :integer
  end
end
