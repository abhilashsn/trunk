class ChangeStatusLengthInReasonCodes < ActiveRecord::Migration
  def up
    change_column :reason_codes, :status, :string, :limit => 25, :default => 'NEW'
  end

  def down
    change_column :reason_codes, :status, :string
  end
end
