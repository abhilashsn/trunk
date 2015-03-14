class ChangePaymentFloatToDecimal < ActiveRecord::Migration
  def up
    change_column :capitation_accounts, :payment, :decimal, :precision => 10, :scale => 2
  end

  def down
    change_column :capitation_accounts, :payment, :float
  end
end
