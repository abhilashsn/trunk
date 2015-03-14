class CreateEraExceptions < ActiveRecord::Migration
  def change
    create_table :era_exceptions do |t|
      t.string :process
      t.string :code
      t.text :description
      t.integer :era_id

      t.timestamps
    end
  end
end
