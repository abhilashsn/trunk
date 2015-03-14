class CreateBalanceRecordConfigs < ActiveRecord::Migration
  def up
    create_table :balance_record_configs do |t|
      t.column :first_name, :string, :limit => 35
      t.column :last_name, :string, :limit => 35
      t.column :account_number, :string, :limit => 30
      t.column :is_payer_the_patient , :boolean
      t.column :category, :string, :limit => 25
      t.column :source_of_adjustment , :string, :limit => 15
      t.column :facility_id , :integer
      t.timestamps
    end
  end

  def down
    drop_table :balance_record_configs
  end
end
