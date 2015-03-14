class AddColumnCheckNumberAndPayerNameAndJobIdToReasonCodes < ActiveRecord::Migration
  def change
    add_column :reason_codes, :check_number, :string, :limit => 30
    add_column :reason_codes, :payer_name, :string
    add_column :reason_codes, :job_id, :integer
  end
end
