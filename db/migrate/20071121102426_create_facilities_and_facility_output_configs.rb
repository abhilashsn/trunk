# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateFacilitiesAndFacilityOutputConfigs < ActiveRecord::Migration
  def up
    create_table :facilities do |t|
      t.column :name, :string
      t.column :details, :text
    end
     create_table :facility_output_configs do |t|
      t.column :facility_id, :integer
      t.column :eob_type, :string
      t.column :combine_pay_corr, :boolean, :default => false
      t.column :group, :string
      t.column :format, :string
      t.column :multi_transac, :boolean, :default => false
      t.column :file_name_components, :string
      t.column :details, :text
      t.timestamps
  end
  end

  def down
    drop_table :facilities
    drop_table :facility_output_configs
  end
end
