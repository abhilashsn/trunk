class CreateErrorPopups < ActiveRecord::Migration
  def up
    create_table :error_popups do |t|
      t.column :comment, :string
      t.column :payer_id, :string
      t.column :facility_id, :integer
      t.column :start_datetime, :date
      t.column :end_datetime, :date
    end
    execute "ALTER TABLE error_popups ADD CONSTRAINT error_popups_idfk_1 FOREIGN KEY (facility_id)
         REFERENCES facilities(id)"
  end

  def down
    execute "ALTER TABLE error_popups DROP FOREIGN KEY error_popups_idfk_1"
    drop_table :error_popups
  end
end
