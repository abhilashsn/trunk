# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateDefaultSamplingRate < ActiveRecord::Migration
  def up
    execute "INSERT INTO sampling_rates(slab,value) VALUES('95-100',5)"
    execute "INSERT INTO sampling_rates(slab,value) VALUES('90-94',10)"
    execute "INSERT INTO sampling_rates(slab,value) VALUES('85-89',15)"
    execute "INSERT INTO sampling_rates(slab,value) VALUES('80-84',18)"
    execute "INSERT INTO sampling_rates(slab,value) VALUES('75-79',20)"
    execute "INSERT INTO sampling_rates(slab,value) VALUES('00-74',25)"
  end

  def down
    User.delete_all
  end
end
