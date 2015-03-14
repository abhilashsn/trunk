# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateSiteSettings < ActiveRecord::Migration
  def up
    create_table :site_settings do |t|
      t.column :show_userid, :boolean, :default => true
      t.column :per_page, :integer, :default => 30
    end
    execute "INSERT INTO site_settings(show_userid,per_page) VALUES(1,30)"
  end

  def down
    drop_table :site_settings
  end
end

