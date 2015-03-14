class AddOcrReportRelatedFieldsToJobs < ActiveRecord::Migration
  def change
     add_column :jobs, :total_ocr_fields, :integer
     add_column :jobs, :total_high_confidence_fields, :integer
     add_column :jobs, :total_edited_fields, :integer
  end
end
