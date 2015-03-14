class ChangeBatchTimeDateTimeToTime < ActiveRecord::Migration
  def up
    change_column :batches, :batch_time, :time
  end

  def down
    change_column :batches, :batch_time, :datetime
  end
end
