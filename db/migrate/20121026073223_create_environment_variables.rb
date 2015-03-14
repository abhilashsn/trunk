class CreateEnvironmentVariables < ActiveRecord::Migration
  def change
    create_table :environment_variables do |t|
      t.string :name
      t.integer :value
      t.text :description
    end
  end
end
