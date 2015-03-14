class CreateFacilityPlanTypes < ActiveRecord::Migration
  def change
    create_table :facility_plan_types do |t|
      t.string :plan_type, :limit => 20
      t.references :client
      t.references :facility
      t.references :payer
      t.timestamps
    end
  end
end
