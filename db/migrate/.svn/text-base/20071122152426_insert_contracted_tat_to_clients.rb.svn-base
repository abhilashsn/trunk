# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class InsertContractedTatToClients < ActiveRecord::Migration
  def up
    Client.update_all("contracted_tat = 20", "name != 'Triad'")
    Client.update_all("contracted_tat = 6", "name = 'Triad'")
  end

  def down
  end
end
