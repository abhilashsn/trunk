class AddFieldNameToEobErrors < ActiveRecord::Migration
  def change
    add_column :eob_errors, :field_name, :string, :after => :error_type
  end
end
