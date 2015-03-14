# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateShifts < ActiveRecord::Migration
  def up
    create_table :shifts do |t|
      t.column :name, :string
      t.column :start_time, :time
      t.column :duration, :float
    end

    execute "INSERT INTO shifts(name,start_time,duration) VALUES('General','2000-01-01 00:00:00',23)"
    shifts = ['Morning', 'Afternoon', 'Night']
    shifts.each do |shift|
      execute "INSERT INTO shifts(name) VALUES('#{shift}')"
    end
    # shifts.each {|s| new_shift = Shift.new(:name => s); new_shift.save!}
  end

  def down
    drop_table :shifts
  end
end
