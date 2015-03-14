# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class SeparateProcessorAndQa < ActiveRecord::Migration
  def up
    add_column :jobs, :qa_id, :integer,:references=>:users
  #  add_foreign_key (:jobs,:qa_id,:users,:id,:name => :fk_qa_id)

   # Rails 3.1 TODO
    qa_jobs = Job.find(:all).select {|job| job.status == ProcessorStatus::ALLOCATED}
    qa_jobs.each do |job|
      job.qa_id = job.user_id
      job.user_id = nil
      job.update
    end
   remove_column :jobs,:user_id
   add_column :jobs,  :processor_id,:integer,:references => :users
   # add_foreign_key (:jobs,:processor_id,:users,:id,:name => :fk_processor_id)
  end

  def down
    add_column :jobs,:user_id,:integer,:references=>:users
    #remove_foreign_key :jobs,:fk_processor_id
    remove_column :jobs,:processor_id
    #    rename_column :jobs, :processor_id, :user_id
    
    qa_jobs = Job.find(:all).select {|job| job.status == ProcessorStatus::ALLOCATED}
    qa_jobs.each do |job|
      job.user_id = job.qa_id
      job.update
    end
   # remove_foreign_key :jobs,:fk_qa_id
    remove_column :jobs, :qa_id
  end
end
