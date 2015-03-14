class CreateCrosswalks < ActiveRecord::Migration
  def change
    create_table :crosswalks do |t|
      t.references :client
      t.references :facility
      t.references :payer
      t.integer :hipaa_code_id, :null => false
      t.string :crosswalk_hipaa_code, :limit => 5, :null => false
      t.date :created_date
      t.date :updated_date

      t.timestamps
    end
    add_index :crosswalks, :client_id
    add_index :crosswalks, :facility_id
    add_index :crosswalks, :payer_id
  end
end
