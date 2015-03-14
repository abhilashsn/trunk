class AddMissingUserRelatedFk < ActiveRecord::Migration
  def up
    # add_foreign_key(:users, :shift_id, :shifts,:id ,:name => :fk_users_shift_id)
    # add_foreign_key(:eob_qas, :qa_id, :users,:id ,:name => :fk_eob_qas_users_id)

    #add a foreign key
    execute <<-SQL
      ALTER TABLE users
        ADD CONSTRAINT fk_users_shift_id
        FOREIGN KEY (shift_id)
        REFERENCES shifts(id)
    SQL

    execute <<-SQL
      ALTER TABLE eob_qas
        ADD CONSTRAINT fk_eob_qas_users_id
        FOREIGN KEY (qa_id)
        REFERENCES users(id)
    SQL

  end

  def down
    execute "ALTER TABLE users DROP FOREIGN KEY fk_users_shift_id"
    execute "ALTER TABLE eob_qas DROP FOREIGN KEY fk_eob_qas_users_id"
    # remove_foreign_key(:users, :fk_users_shift_id ) 
    # remove_foreign_key(:eob_qas, :fk_eob_qas_users_id ) 
  end
end
