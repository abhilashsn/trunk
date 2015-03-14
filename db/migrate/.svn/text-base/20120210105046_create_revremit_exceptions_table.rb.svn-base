class CreateRevremitExceptionsTable < ActiveRecord::Migration
  def up
    create_table :revremit_exceptions do |t|
      t.column :exception_type, :string
      t.column :client_exception, :text
      t.column :system_exception, :text
      t.timestamps
    end
  end

  def down
    drop_table :revremit_exceptions
  end
end
