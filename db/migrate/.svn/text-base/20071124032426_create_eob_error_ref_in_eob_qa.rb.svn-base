# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateEobErrorRefInEobQa < ActiveRecord::Migration
  def up
    add_column :eob_qas, :eob_error_id, :integer,:references => :eob_errors
    # add_foreign_key(:eob_qas, :eob_error_id, :eob_errors, :id,:name => :fk_eob_error_id )
    remove_column :eob_errors, :eob_qa_id

    #add a foreign key
    execute <<-SQL
      ALTER TABLE eob_qas
        ADD CONSTRAINT fk_eob_error_id
        FOREIGN KEY (eob_error_id)
        REFERENCES eob_errors(id)
    SQL

  end

  def down
    execute "ALTER TABLE eob_qas DROP FOREIGN KEY fk_eob_error_id"
    # remove_foreign_key(:eob_qas, :fk_eob_error_id )
    remove_column :eob_qas, :eob_error_id
    add_column :eob_errors, :eob_qa_id, :integer
  end
end
