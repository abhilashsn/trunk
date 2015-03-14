class AddOriginalPayerIdToPayers < ActiveRecord::Migration
    def change
        add_column :check_informations, :original_payer_id, :integer
        add_column :micr_line_informations, :original_payer_id, :integer
  end
end
