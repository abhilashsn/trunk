class CreateWebServiceLogs < ActiveRecord::Migration
  def change
    create_table :web_service_logs do |t|
      t.string :service, :null => false
      t.string :query, :null => false
      t.integer :response_code, :null => false
      t.integer :response_time, :null => false

      t.timestamps
    end
  end
end
