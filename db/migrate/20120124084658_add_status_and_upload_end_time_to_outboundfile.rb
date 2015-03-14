class AddStatusAndUploadEndTimeToOutboundfile < ActiveRecord::Migration
  def change
    add_column :outbound_file_informations, :status, :string , :limit=>64
    add_column :outbound_file_informations, :upload_end_time, :datetime
  end
end
