class CreateConfigSettings < ActiveRecord::Migration
  def change
    create_table :config_settings do |t|
      t.references :partner
      t.references :client
      t.references :facility
      t.string :config_level
      t.text :details
      t.string :output_type

      t.timestamps
    end
    add_index :config_settings, :partner_id
    add_index :config_settings, :client_id
    add_index :config_settings, :facility_id
  end
end
