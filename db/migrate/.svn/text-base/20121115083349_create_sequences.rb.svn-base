class CreateSequences < ActiveRecord::Migration
  def up
    create_table :sequences, :id => false do |t|
      t.string :name
      t.integer :value
    end
    execute "ALTER TABLE sequences ADD PRIMARY KEY (name);"
  end
  
  def down
    drop_table :sequences
  end
end
