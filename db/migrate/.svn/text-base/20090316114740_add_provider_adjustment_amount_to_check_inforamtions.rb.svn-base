class AddProviderAdjustmentAmountToCheckInforamtions < ActiveRecord::Migration
  def up
     add_column :check_informations,:provider_adjustment_amount ,:decimal,:precision => 10, :scale => 2
  end

  def down
     remove_column :check_informations,:provider_adjustment_amount
  end
end
