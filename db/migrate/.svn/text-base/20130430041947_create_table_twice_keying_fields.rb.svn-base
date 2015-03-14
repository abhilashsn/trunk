class CreateTableTwiceKeyingFields < ActiveRecord::Migration
  def change
    create_table :twice_keying_fields do |t|
      t.string :field_name
      t.integer :client_id
      t.integer :facility_id
      t.integer :reason_code_set_name_id
      t.integer :processor_id
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
