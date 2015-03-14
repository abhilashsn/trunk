# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateDefaultBatchStatus < ActiveRecord::Migration
  def up
    %w{New Processing Complete}.each do |vl|
      execute "INSERT INTO statuses(value) VALUES('#{vl}')"
    end
  end

  def down
    Status.delete_all
  end
end
