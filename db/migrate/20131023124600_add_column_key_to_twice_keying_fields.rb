class AddColumnKeyToTwiceKeyingFields < ActiveRecord::Migration
  def change
    add_column :twice_keying_fields, :key, :integer
  end
end
