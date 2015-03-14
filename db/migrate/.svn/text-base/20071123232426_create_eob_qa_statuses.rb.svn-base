# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateEobQaStatuses < ActiveRecord::Migration
  def up
    create_table :eob_qa_statuses do |t|
      t.column :name, :string
    end
    # EobQaStatus.enumeration_model_updates_permitted = true
    statuses = ['Accepted', 'Rejected']
    statuses.each do |value|
      execute "INSERT INTO  eob_qa_statuses(name) VALUES('#{value}')"
    end
    #  EobQaStatus.enumeration_model_updates_permitted = false
  end

  def down
    drop_table :eob_qa_statuses
  end
end
