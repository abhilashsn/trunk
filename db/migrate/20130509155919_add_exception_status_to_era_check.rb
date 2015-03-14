class AddExceptionStatusToEraCheck < ActiveRecord::Migration
  def change
    add_column :era_checks, :exception_status, :string
  end
end
