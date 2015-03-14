class CreateUsers < ActiveRecord::Migration
  def up
    create_table "users", :force => true do |t|
      t.column :login,                     :string, :limit => 40
      t.column :name,                      :string, :limit => 100, :default => '', :null => true
      t.column :email,                     :string, :limit => 100
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string, :limit => 40
      t.column :remember_token_expires_at, :datetime
      t.column :status,                      :string, :default => 'Offline'
      t.column :image_permision,             :string
      t.column :image_grid_permision,        :string
      t.column :image_835_permision,        :string
      t.column :activity_log_permission,       :string, :default => 1
      t.column :allocation_status,  :boolean,   :default => 1
      t.column :last_activity_at,  :datetime      
      t.column :batch_status_permission,    :string
      t.column :file_837_report_permission, :string
      t.column :role, :string
      t.column :is_deleted,  :boolean, :default => false
      t.column :eob_accuracy,  :float, :default => 100, :null => true
      t.column :field_accuracy,  :float, :default => 100, :null => true
      t.column :shift_id,  :integer, :limit => 11, :null => true
      t.column :total_eobs,  :integer, :limit => 11, :default => 0, :null => true
      t.column :rejected_eobs,  :integer, :limit => 11, :default => 0, :null => true
      t.column :processing_rate_triad,      :integer, :default => 5     
      t.column :processing_rate_others,     :integer, :default => 8
      t.column :total_fields,     :integer, :default => 0
      t.column :total_incorrect_fields,   :integer, :default => 0
      t.column :eob_qa_checked,     :integer, :default => 0
    end
    add_index :users, :login, :unique => true
  end

  def down
    drop_table "users"
  end
end