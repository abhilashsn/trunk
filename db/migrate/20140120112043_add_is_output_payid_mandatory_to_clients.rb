class AddIsOutputPayidMandatoryToClients < ActiveRecord::Migration
  def change
    add_column :clients, :is_output_payid_mandatory, :boolean, :default => 0
  end
end
