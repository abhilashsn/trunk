class ChangeDatatypeInCapitationAccount < ActiveRecord::Migration
  def up
    change_column :capitation_accounts, :account, :string
    change_column :capitation_accounts, :payment, :float
  end

  def down
    change_column :capitation_accounts, :account, :integer
    change_column :capitation_accounts, :payment, :integer
  end
end
