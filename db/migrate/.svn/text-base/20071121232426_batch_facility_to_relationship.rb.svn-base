# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class BatchFacilityToRelationship < ActiveRecord::Migration
  def up
    begin
      add_column "batches", "facility_id", :integer
      Batch.reset_column_information
      say_with_time "Converting from facility fields to relationship" do
        Batch.find(:all).each do |b|
          f = Facility.find_by_name(b.attributes["facility"])
          b.facility = f
          b.update
        end
      end
      remove_column "batches", "facility"
    rescue ActiveRecord::StatementInvalid => e
      if e.message =~ /Duplicate column name/
        say "The column facility_id already exists. Skipping upgrade."
      else
        say "Unexpected exception occurred."
        say e.message
        raise
      end
    end
  end

  def down
    add_column "batches", "facility", :string
    Batch.reset_column_information
    say_with_time "Converting copying values from Facilities into field on Batches" do
      Batch.find(:all).each do |b|
        # TODO: Make this actually work. As is, b.attributes['facility'] comes up nil
  #      p b.facility.name
  #      p b.attributes['facility']
        b.attributes["facility"] = b.facility.name
  #      p b.attributes['facility']
        b.update
      end
    end
    remove_column "batches", "facility_id"
  end
end
