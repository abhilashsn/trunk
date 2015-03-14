class CreateImageTypes < ActiveRecord::Migration
  def up
    create_table :image_types do |t|
      t.column :image_type , :string, :limit => 3
      t.column :patient_account_number, :string, :limit => 30
      t.column :patient_last_name , :string, :limit => 35
      t.column :patient_first_name , :string, :limit => 35
      t.column :image_page_number, :integer
      t.column :images_for_job_id, :integer
      t.column :insurance_payment_eob_id, :integer
      t.timestamps
    end
  end

  def down
    drop_table :image_types
  end
end
