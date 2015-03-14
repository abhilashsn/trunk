class CreateTempJobs < ActiveRecord::Migration
  def change
    create_table :temp_jobs do |t|
      t.integer :aba_number
      t.integer :account_number
      t.integer :check_number
      t.decimal :check_amount, :precision => 8, :scale => 2
      t.integer :image_count
      t.string :image_from
      t.string :image_to
      t.integer :job_id

      t.timestamps
    end
  end
end
