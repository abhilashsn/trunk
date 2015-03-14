class AddTatCommentToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :tat_comment, :string
  end
end
