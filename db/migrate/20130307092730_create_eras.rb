class CreateEras < ActiveRecord::Migration
  def change
    create_table :eras do |t|

      t.timestamps
      t.string   :file_name
      t.integer  :file_size
      t.string   :file_md5_hash
      t.datetime :file_arrival_time
      t.string   :file_location
      t.string   :identifier_hash
      t.string   :status
      t.string   :file_path
      t.datetime :xml_conversion_time
      t.integer  :is_duplicate
      t.integer  :parent_era_id
      t.datetime :era_parse_start_time
      t.datetime :era_process_start_time
      t.datetime :era_parse_end_time
      t.datetime :era_process_end_time

    end
  end
end
