class CreateReasonCodeSetNames < ActiveRecord::Migration
  def up
    create_table :reason_code_set_names do |t|
      t.string :name, :limit => 20

      t.timestamps
    end
  end

  def down
    drop_table :reason_code_set_names
  end
end
