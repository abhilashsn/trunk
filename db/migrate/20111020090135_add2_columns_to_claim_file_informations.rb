class Add2ColumnsToClaimFileInformations < ActiveRecord::Migration
  def up
    add_column :claim_file_informations, :sent_to_ap, :boolean, :default => 0
    add_column :claim_file_informations, :bill_print_date, :date
  end

  def down
    remove_column :claim_file_informations, :sent_to_ap
    remove_column :claim_file_informations, :bill_print_date
  end
end
