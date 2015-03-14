# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddPayerToQaCheckedJobs < ActiveRecord::Migration
  def up
    add_column :eob_reports, :payer_id, :integer
    # add_foreign_key(:eob_reports, :payer_id, :payers, :id,:name => :fk_eob_report_payer_id )

    #add a foreign key
    execute <<-SQL
      ALTER TABLE eob_reports
        ADD CONSTRAINT fk_eob_report_payer_id
        FOREIGN KEY (payer_id)
        REFERENCES payers(id)
    SQL

  end
  def down
    execute "ALTER TABLE eob_reports DROP FOREIGN KEY fk_eob_report_payer_id"
    # remove_foreign_key(:eob_reports, :fk_eob_report_payer_id )   
    remove_column :eob_reports, :payer_id
  end
end
