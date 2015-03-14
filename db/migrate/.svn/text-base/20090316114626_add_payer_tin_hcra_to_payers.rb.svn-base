class AddPayerTinHcraToPayers < ActiveRecord::Migration
  def up
    add_column :payers,:payer_tin, :string
    add_column :payers,:hcra_code, :string
  end

  def down
    remove_column :payers,:payer_tin
    remove_column :payers,:hcra_code
  end
end
