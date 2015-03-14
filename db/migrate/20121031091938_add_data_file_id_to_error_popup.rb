class AddDataFileIdToErrorPopup < ActiveRecord::Migration
  def change
     add_column :error_popups, :data_file_id, :integer
   end
end
