class AddEobidToEobQas < ActiveRecord::Migration
  def up
     add_column:eob_qas,:eob_id,:integer
  end

  def down
      remove_column:eob_qas,:eob_id,:integer
  end
end
