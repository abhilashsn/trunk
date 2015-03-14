class CreateProviderAdjustments < ActiveRecord::Migration
  def change
    create_table :provider_adjustments do |t|
      t.column :description , :string, :limit => 100
      t.column :qualifier, :string, :limit => 5
      t.column :amount, :decimal, :precision => 10, :scale => 2
      t.column :patient_account_number, :string, :limit => 30
      t.column :image_page_number, :integer
      t.references :job
      t.timestamps
    end
  end
end
