class CreateCptCodes < ActiveRecord::Migration
  def change
    create_table :cpt_codes do |t|
       t.string :name
      t.timestamps
    end
  end
end
