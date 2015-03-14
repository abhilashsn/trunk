class CreateTableBatchOutputStatuses < ActiveRecord::Migration
 def up
    create_table :batch_output_statuses do |t|
      t.string :batch_status
     end
      %w{OUTPUT_READY COMPLETED OUTPUT_GENERATING OUTPUT_GENERATED OUTPUT_EXCEPTION}.each do |vl|
      execute "INSERT INTO batch_output_statuses(batch_status) VALUES('#{vl}')"
    end
  end

  def down
    drop_table :batch_output_statuses
  end
end
