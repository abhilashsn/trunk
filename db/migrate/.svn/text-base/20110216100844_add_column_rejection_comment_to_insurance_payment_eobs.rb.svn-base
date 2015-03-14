class AddColumnRejectionCommentToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :rejection_comment, :string, :limit => 70
  end

  def down
    remove_column :insurance_payment_eobs, :rejection_comment
  end
end
