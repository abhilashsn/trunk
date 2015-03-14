class CreateMiscSegmentsEras < ActiveRecord::Migration
  def change
    create_table :misc_segments_eras do |t|
      t.references :era
      t.string :segment_level, :limit => 20
      t.string :segment_header, :limit => 3
      t.string :segment_text
      t.integer :segment_line_number_in_file
      t.timestamps
    end
  end
end