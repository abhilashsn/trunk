class AddEnabledForUserDashBoardToFacility < ActiveRecord::Migration
  def change
    add_column :facilities, :enabled_for_user_dashboard, :boolean, :default => false
  end
end
