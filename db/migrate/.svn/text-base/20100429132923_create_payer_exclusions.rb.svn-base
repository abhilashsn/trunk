class CreatePayerExclusions < ActiveRecord::Migration
  def up
    create_table :payer_exclusions, :force => true, :id => false do |t|
      t.integer :facility_id, :null => false
      t.integer :payer_id, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :payer_exclusions
  end
end
