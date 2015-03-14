class AddColumnsCheckNumberAndReasonCodeSetNameIdToReasonCodes < ActiveRecord::Migration
  def up
    change_column :reason_codes, :check_number, :string, :limit => 30
    add_column :reason_codes, :reason_code_set_name_id, :integer
    # add_foreign_key(:reason_codes, :reason_code_set_name_id, :reason_code_set_names, :id, :name => :fk_reason_code_reason_code_set_name_id)
    add_column :reason_codes, :marked_for_deletion, :boolean, :default => 0

    execute <<-SQL
      ALTER TABLE reason_codes
        ADD CONSTRAINT fk_reason_code_reason_code_set_name_id
        FOREIGN KEY (reason_code_set_name_id)
        REFERENCES reason_code_set_names(id)
    SQL

  end

  def down
    # remove_column :reason_codes, :check_number
    remove_column :reason_codes, :reason_code_set_name_id
    # remove_foreign_key(:reason_codes, :fk_reason_code_reason_code_set_name_id )
    remove_column :reason_codes, :marked_for_deletion
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY fk_reason_code_reason_code_set_name_id"
  end
end
