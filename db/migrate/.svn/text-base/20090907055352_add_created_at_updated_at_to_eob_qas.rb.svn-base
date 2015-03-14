class AddCreatedAtUpdatedAtToEobQas < ActiveRecord::Migration
  def up
    add_column :eob_qas, :created_at, :datetime
    add_column :eob_qas, :updated_at, :datetime
  end

  def down
    remove_column :eob_qas, :created_at
    remove_column :eob_qas, :updated_at
  end
end
