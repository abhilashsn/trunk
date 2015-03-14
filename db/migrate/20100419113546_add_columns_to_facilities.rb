class AddColumnsToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :lockbox_number,  :string
    add_column :facilities, :abbr_name,  :string
    add_column :facilities, :tat,  :string
    add_column :facilities, :processing_location,  :string
    add_column :facilities, :production_status,  :string
    add_column :facilities, :image_file_format,  :string
    add_column :facilities, :image_processing_type,  :string
    add_column :facilities, :index_file_format,  :string
    add_column :facilities, :index_file_parser_type,  :string
    add_column :facilities, :batch_load_type,  :string
    add_column :facilities, :ocr_tolerance,  :string
    add_column :facilities, :non_ocr_tolerance,  :string
    add_column :facilities, :claim_file_parser_type,  :string
    add_column :facilities, :commercial_payerid,  :string
    add_column :facilities, :patient_payerid,  :string
    add_column :facilities, :patient_pay_format,  :string
    add_column :facilities, :plan_type,  :string
    add_column :facilities, :default_service_date,  :string
    add_column :facilities, :default_account_number,  :string
    add_column :facilities, :default_cpt_code,  :string
    add_column :facilities, :default_ref_number,  :string
    add_column :facilities, :default_patient_name,  :string
    add_column :facilities, :is_check_date_as_batch_date,  :boolean, :default => false
  end

  def down
    remove_column :facilities, :lockbox_number
    remove_column :facilities, :abbr_name
    remove_column :facilities, :tat
    remove_column :facilities, :processing_location
    remove_column :facilities, :production_status
    remove_column :facilities, :image_file_format
    remove_column :facilities, :image_processing_type
    remove_column :facilities, :index_file_format
    remove_column :facilities, :index_file_parser_type
    remove_column :facilities, :batch_load_type
    remove_column :facilities, :ocr_tolerance
    remove_column :facilities, :non_ocr_tolerance
    remove_column :facilities, :claim_file_parser_type
    remove_column :facilities, :commercial_payerid
    remove_column :facilities, :patient_payerid
    remove_column :facilities, :patient_pay_format
    remove_column :facilities, :plan_type
    remove_column :facilities, :default_service_date
    remove_column :facilities, :default_account_number
    remove_column :facilities, :default_cpt_code
    remove_column :facilities, :default_ref_number
    remove_column :facilities, :default_patient_name
    remove_column :facilities, :is_check_date_as_batch_date
  end
end
