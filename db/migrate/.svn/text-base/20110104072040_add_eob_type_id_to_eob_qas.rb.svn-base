class AddEobTypeIdToEobQas < ActiveRecord::Migration
  def up
    add_column :eob_qas, :eob_type_id, :integer, :default => 1
  end

  def down
    remove_column :eob_qas, :eob_type_id
  end
end
