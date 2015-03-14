class CreateLogTableForPayerReasonCode < ActiveRecord::Migration
  def up
    create_table :activity_logs do |t|
      t.column :object_id, :integer
      t.column :action, :string
      t.column :actor_id, :integer
    end
  end

  def down
    drop_table :activity_logs
  end
end
