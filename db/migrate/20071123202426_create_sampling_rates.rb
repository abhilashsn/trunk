# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateSamplingRates < ActiveRecord::Migration
  def up
    create_table :sampling_rates do |t|
      t.column :slab, :string
      t.column :value, :integer, :default => 5
    end
  end

  def down
    drop_table :sampling_rates
  end
end
