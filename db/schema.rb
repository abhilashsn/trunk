# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130430050534) do

  create_table "aba_dda_lookups", :force => true do |t|
    t.string   "aba_number"
    t.string   "dda_number"
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ach_files", :force => true do |t|
    t.string   "file_name"
    t.integer  "file_size"
    t.string   "file_creation_date"
    t.string   "file_creation_time"
    t.string   "file_hash"
    t.string   "file_arrival_date"
    t.string   "file_arrival_time"
    t.datetime "file_load_start_time"
    t.datetime "file_load_end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ansi_remark_codes", :force => true do |t|
    t.string   "adjustment_code"
    t.string   "adjustment_code_description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active"
  end

  create_table "balance_record_configs", :force => true do |t|
    t.string   "first_name",           :limit => 35
    t.string   "last_name",            :limit => 35
    t.string   "account_number",       :limit => 30
    t.boolean  "is_payer_the_patient"
    t.string   "category",             :limit => 25
    t.string   "source_of_adjustment", :limit => 15
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_rejection_comments", :force => true do |t|
    t.string "comment"
  end

  create_table "batch_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "batch_temps", :force => true do |t|
    t.integer  "batch_id"
    t.datetime "batch_date"
  end

  add_index "batch_temps", ["batch_id"], :name => "idx_batch_temps_lookup"

  create_table "batches", :force => true do |t|
    t.string   "batchid"
    t.date     "date"
    t.integer  "facility_id"
    t.datetime "arrival_time"
    t.datetime "target_time"
    t.string   "status",                                                                             :default => "NEW"
    t.integer  "eob"
    t.text     "details"
    t.datetime "completion_time"
    t.integer  "payer_id"
    t.string   "comment"
    t.datetime "contracted_time"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.datetime "created_at"
    t.boolean  "correspondence",                                                                     :default => false
    t.string   "lockbox",                               :limit => 20
    t.string   "bank_deposit_id_number",                :limit => 20
    t.string   "client_id",                             :limit => 20
    t.datetime "output_835_generated_time"
    t.string   "file_name"
    t.string   "cut",                                   :limit => 1
    t.datetime "estimated_completion_time"
    t.string   "index_batch_number"
    t.time     "batch_time"
    t.integer  "inbound_file_information_id"
    t.decimal  "total_charge",                                        :precision => 10, :scale => 2
    t.decimal  "total_excluded_charge",                               :precision => 10, :scale => 2
    t.datetime "output_835_start_time"
    t.datetime "expected_completion_time"
    t.string   "tat_comment"
    t.boolean  "client_wise_auto_allocation_enabled",                                                :default => false
    t.boolean  "payer_wise_auto_allocation_enabled",                                                 :default => false
    t.integer  "priority",                              :limit => 2,                                 :default => 5
    t.datetime "output_835_posting_time"
    t.string   "qa_status",                             :limit => 20,                                :default => "NEW"
    t.datetime "processing_start_time"
    t.datetime "processing_end_time"
    t.string   "ocr_zip_file_name"
    t.boolean  "facility_wise_auto_allocation_enabled",                                              :default => false
    t.string   "file_meta_hash"
    t.string   "orbo_account_number",                   :limit => 50
  end

  add_index "batches", ["batchid"], :name => "index_batches_on_batchid"
  add_index "batches", ["date"], :name => "index_batches_on_date"
  add_index "batches", ["facility_id"], :name => "batches_idfk_1"
  add_index "batches", ["inbound_file_information_id"], :name => "fk_inbound_file_information_id"
  add_index "batches", ["status"], :name => "index_batches_on_status"

  create_table "business_unit_indicator_lookup_fields", :force => true do |t|
    t.integer  "business_unit_indicator"
    t.string   "financial_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "capitation_accounts", :force => true do |t|
    t.string   "account"
    t.decimal  "payment",            :precision => 10, :scale => 2
    t.integer  "checknumber"
    t.integer  "batch_id"
    t.integer  "user_id"
    t.string   "payer_name"
    t.string   "patient_first_name"
    t.string   "patient_last_name"
    t.string   "patient_initial"
    t.string   "patient_suffix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "check_informations", :force => true do |t|
    t.integer  "job_id"
    t.integer  "payer_id"
    t.date     "check_date"
    t.string   "check_number",                  :limit => 30
    t.decimal  "check_amount",                                :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
    t.string   "check_regenerate"
    t.string   "check_regenerate_comment"
    t.string   "payer_type"
    t.decimal  "provider_adjustment_amount",                  :precision => 10, :scale => 2
    t.string   "payment_type",                  :limit => 30
    t.integer  "micr_line_information_id"
    t.text     "provider_adjustment_qualifier"
    t.date     "check_received_date"
    t.date     "check_mailed_date"
    t.string   "guid",                          :limit => 36
    t.string   "transaction_id",                :limit => 64
    t.string   "alternate_payer_name"
    t.string   "payment_method",                :limit => 10
    t.boolean  "mismatch_transaction",                                                       :default => false
    t.string   "payee_npi",                     :limit => 10
    t.string   "payee_tin",                     :limit => 9
    t.string   "payee_name"
  end

  add_index "check_informations", ["check_number"], :name => "by_check_number"
  add_index "check_informations", ["job_id"], :name => "check_informations_idfk_1"
  add_index "check_informations", ["payer_id"], :name => "check_informations_idfk_2"

  create_table "claim_file_informations", :force => true do |t|
    t.string   "zip_file_name"
    t.integer  "facility_id"
    t.string   "name"
    t.datetime "arrival_time"
    t.float    "size",                                      :default => 0.0
    t.datetime "load_start_time"
    t.datetime "load_end_time"
    t.string   "status",                                    :default => "FAILURE"
    t.integer  "total_claim_count",                         :default => 0
    t.integer  "loaded_claim_count",                        :default => 0
    t.integer  "total_svcline_count",                       :default => 0
    t.integer  "loaded_svcline_count",                      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "claim_file_type",             :limit => 50
    t.boolean  "sent_to_ap",                                :default => false
    t.datetime "bill_print_date"
    t.integer  "inbound_file_information_id"
    t.integer  "output_activity_log_id"
    t.string   "file_header_hash"
    t.string   "file_meta_hash"
    t.integer  "deleted",                                   :default => 0
    t.date     "file_interchange_date"
    t.integer  "client_id"
    t.time     "file_interchange_time"
  end

  add_index "claim_file_informations", ["output_activity_log_id"], :name => "fk_output_activity_log_id"

  create_table "claim_informations", :force => true do |t|
    t.string   "patient_first_name",                       :limit => 35
    t.string   "patient_last_name",                        :limit => 30
    t.string   "patient_middle_initial",                   :limit => 20
    t.string   "patient_suffix",                           :limit => 20
    t.string   "patient_account_number",                   :limit => 40
    t.string   "insured_id"
    t.decimal  "total_charges",                                           :precision => 10, :scale => 2
    t.string   "billing_provider_tin",                     :limit => 14
    t.string   "billing_provider_npi",                     :limit => 14
    t.string   "billing_provider_address_one",             :limit => 100
    t.string   "billing_provider_city",                    :limit => 30
    t.string   "billing_provider_state",                   :limit => 5
    t.string   "billing_provider_zipcode",                 :limit => 10
    t.string   "claim_frequency_type_code",                :limit => 30
    t.string   "payee_name",                               :limit => 30
    t.string   "payee_address_one",                        :limit => 30
    t.string   "payee_city",                               :limit => 30
    t.string   "payee_state",                              :limit => 30
    t.string   "payee_zipcode",                            :limit => 30
    t.string   "provider_ein",                             :limit => 15
    t.integer  "facility_id"
    t.string   "provider_last_name",                       :limit => 28
    t.string   "provider_suffix",                          :limit => 20
    t.string   "provider_first_name",                      :limit => 28
    t.string   "provider_middle_initial",                  :limit => 28
    t.string   "provider_npi",                             :limit => 15
    t.string   "billing_provider_organization_name"
    t.string   "payer_name"
    t.string   "payer_address"
    t.string   "payer_city"
    t.string   "payer_state",                              :limit => 3
    t.string   "payer_zipcode"
    t.string   "subscriber_first_name",                    :limit => 35
    t.string   "subscriber_last_name",                     :limit => 30
    t.string   "subscriber_middle_initial",                :limit => 20
    t.string   "subscriber_suffix",                        :limit => 20
    t.string   "drg_code",                                 :limit => 6
    t.string   "plan_type",                                :limit => 20
    t.string   "facility_type_code"
    t.string   "policy_number"
    t.string   "claim_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "patient_identification_number"
    t.string   "patient_medistreams_id"
    t.integer  "claim_file_information_id"
    t.string   "iplan"
    t.string   "supplemental_iplan"
    t.string   "legacy_provider_number"
    t.date     "claim_statement_period_start_date"
    t.date     "claim_statement_period_end_date"
    t.string   "carrier_code"
    t.string   "claim_number"
    t.integer  "business_unit_indicator"
    t.string   "payee_npi"
    t.string   "payee_tin"
    t.text     "additional_claim_informations"
    t.string   "payid",                                    :limit => 60
    t.string   "provider_phone_number",                    :limit => 50
    t.string   "social_security_number",                   :limit => 50
    t.integer  "client_id"
    t.string   "xpeditor_document_number"
    t.date     "date_of_birth"
    t.string   "plan_code"
    t.string   "claim_adjudication_sequence"
    t.string   "rendering_provider_taxonomy_code",         :limit => 50
    t.string   "claim_id_hash"
    t.boolean  "active"
    t.string   "STATUS"
    t.string   "reason_for_duplication"
    t.datetime "bill_print_date"
    t.integer  "retained_claim_id"
    t.string   "changed_param"
    t.integer  "billing_provider_hierarchical_level_code",                                               :default => 20, :null => false
    t.string   "billing_provider_additional_identifier",   :limit => 50
    t.integer  "subscriber_hierarchical_level_code",                                                     :default => 22, :null => false
    t.integer  "individual_relationship_code",                                                           :default => 18, :null => false
    t.string   "subscriber_name_suffix",                   :limit => 10
    t.string   "subscriber_address_line",                  :limit => 55
    t.string   "subscriber_city_name",                     :limit => 30
    t.string   "subscriber_state_code",                    :limit => 2
    t.string   "subscriber_zip_code",                      :limit => 15
    t.string   "payer_identifier",                         :limit => 80
    t.integer  "patient_hierarchical_level_code",                                                        :default => 23, :null => false
    t.string   "patient_identification_code_qualifier",    :limit => 2
    t.string   "patient_primary_identifier",               :limit => 80
    t.string   "patient_address_line",                     :limit => 55
    t.string   "patient_city_name",                        :limit => 30
    t.string   "patient_state_code",                       :limit => 2
    t.string   "patient_zip_code",                         :limit => 15
    t.string   "claim_original_reference_number",          :limit => 50
    t.decimal  "payer_paid_amount",                                       :precision => 18, :scale => 0
    t.date     "claim_end_date"
    t.string   "employers_identification_number",          :limit => 50
    t.string   "payer_claim_original_reference_number",    :limit => 50
    t.string   "billing_provider_taxonomy_code",           :limit => 50
    t.string   "medical_record_number",                    :limit => 50
  end

  add_index "claim_informations", ["active"], :name => "active"
  add_index "claim_informations", ["claim_id_hash"], :name => "claim_id_hash"
  add_index "claim_informations", ["retained_claim_id"], :name => "retained_claim_id"

  create_table "claim_level_adjustments_eras", :force => true do |t|
    t.integer  "insurance_payment_era_id"
    t.string   "cas_group_code",           :limit => 2
    t.string   "cas_hipaa_code",           :limit => 5
    t.decimal  "adjustment_amount",                     :precision => 18, :scale => 2
    t.integer  "adjustment_quantity",      :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "claim_level_adjustments_eras", ["insurance_payment_era_id"], :name => "FK_claim_adjustments_ins_pay_era"

  create_table "claim_level_service_lines", :force => true do |t|
    t.string   "description",                                             :null => false
    t.decimal  "amount",                   :precision => 10, :scale => 2, :null => false
    t.integer  "insurance_payment_eob_id",                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "claim_level_service_lines", ["insurance_payment_eob_id"], :name => "by_insurance_payment_eob_id"

  create_table "claim_service_informations", :force => true do |t|
    t.date     "service_from_date"
    t.date     "service_to_date"
    t.decimal  "days_units",                                          :precision => 10, :scale => 2
    t.string   "cpt_hcpcts",                            :limit => 20
    t.decimal  "charges",                                             :precision => 10, :scale => 2
    t.string   "modifier1",                             :limit => 2
    t.string   "modifier2",                             :limit => 2
    t.string   "modifier3",                             :limit => 2
    t.string   "modifier4",                             :limit => 2
    t.decimal  "quantity",                                            :precision => 8,  :scale => 2
    t.decimal  "non_covered_charge",                                  :precision => 8,  :scale => 2
    t.string   "revenue_code",                          :limit => 6
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "claim_information_id"
    t.string   "provider_control_number",               :limit => 30
    t.text     "additional_claim_service_informations"
    t.string   "service_location"
    t.decimal  "expected_payment",                                    :precision => 10, :scale => 2
    t.string   "service_id_hash"
    t.string   "changed_param"
    t.string   "procedure_code",                        :limit => 48
    t.decimal  "line_item_charge_amount",                             :precision => 10, :scale => 2
    t.decimal  "service_unit_count",                                  :precision => 10, :scale => 2
    t.string   "place_of_service_code",                 :limit => 2
    t.string   "identification_code",                   :limit => 80
    t.string   "product_or_service_id_qualifier",       :limit => 2
    t.string   "product_service_id",                    :limit => 48
    t.string   "service_description",                   :limit => 80
    t.decimal  "remaining_patient_liability_amount",                  :precision => 10, :scale => 2
    t.integer  "service_units_days"
    t.integer  "unit_rate"
    t.decimal  "monetary_amount",                                     :precision => 10, :scale => 2
    t.string   "product_service_id_sv301",              :limit => 48
    t.string   "facility_code_value",                   :limit => 2
    t.string   "tooth_code",                            :limit => 50
    t.integer  "line_number",                                                                        :default => 0, :null => false
  end

  add_index "claim_service_informations", ["claim_information_id"], :name => "index_claim_service_informations_on_claim_information_id"
  add_index "claim_service_informations", ["service_id_hash"], :name => "service_id_hash"

  create_table "claim_types", :force => true do |t|
    t.string "claim_type"
  end

  create_table "claim_validation_exceptions", :force => true do |t|
    t.integer  "insurance_payment_eob_id"
    t.integer  "claim_information_id"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_activity_logs", :force => true do |t|
    t.integer  "user_id"
    t.string   "activity"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "job_id"
    t.integer  "eob_id"
    t.string   "eob_type"
  end

  create_table "client_codes", :force => true do |t|
    t.string   "group_code"
    t.string   "adjustment_code"
    t.string   "adjustment_code_description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_images_to_jobs", :force => true do |t|
    t.integer  "job_id"
    t.integer  "images_for_job_id"
    t.integer  "sub_job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_images_to_jobs", ["images_for_job_id"], :name => "client_images_to_jobs_idfk_2"
  add_index "client_images_to_jobs", ["job_id"], :name => "client_images_to_jobs_idfk_1"

  create_table "client_reported_errors", :force => true do |t|
    t.string   "error_type",               :limit => 25
    t.string   "error_description",        :limit => 2000
    t.integer  "error_count"
    t.integer  "eob_count"
    t.string   "status",                   :limit => 20
    t.string   "source",                   :limit => 20
    t.string   "comment",                  :limit => 20
    t.date     "reported_date"
    t.string   "site_code",                :limit => 15
    t.date     "batch_date"
    t.string   "batchid",                  :limit => 15
    t.integer  "batch_id"
    t.string   "check_number",             :limit => 30
    t.integer  "check_informtion_id"
    t.string   "payid",                    :limit => 10
    t.integer  "payer_id"
    t.string   "patient_account_number",   :limit => 30
    t.integer  "insurance_payment_eob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "user_date"
  end

  add_index "client_reported_errors", ["batch_date"], :name => "index_client_reported_errors_on_batch_date"
  add_index "client_reported_errors", ["user_date"], :name => "index_client_reported_errors_on_user_date"

  create_table "clients", :force => true do |t|
    t.string   "name"
    t.integer  "tat"
    t.integer  "contracted_tat"
    t.integer  "partner_id"
    t.string   "group_code",                    :limit => 10,  :null => false
    t.string   "type_code",                     :limit => 10
    t.string   "type_desc",                     :limit => 100
    t.string   "channel",                       :limit => 50
    t.string   "partener_bank_group_code",      :limit => 50
    t.text     "custom_fields"
    t.integer  "internal_tat"
    t.integer  "max_eobs_per_job"
    t.integer  "max_jobs_per_user_client_wise"
    t.integer  "max_jobs_per_user_payer_wise"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clients", ["group_code"], :name => "clients_group_code_index", :unique => true

  create_table "clients_users", :force => true do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.integer "eobs_processed"
    t.boolean "eligible_for_auto_allocation", :default => false
  end

  add_index "clients_users", ["client_id"], :name => "clients_users_idfk_1"
  add_index "clients_users", ["eligible_for_auto_allocation"], :name => "index_clients_users_on_eligible_for_auto_allocation"
  add_index "clients_users", ["user_id"], :name => "clients_users_idfk_2"

  create_table "contact_informations", :force => true do |t|
    t.string   "address_line_one",   :limit => 100
    t.string   "address_line_two",   :limit => 100
    t.string   "address_line_three", :limit => 100
    t.string   "city",               :limit => 50
    t.string   "state",              :limit => 50
    t.string   "zip",                :limit => 10
    t.string   "entity",             :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website",            :limit => 200
  end

  create_table "cpt_codes", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cr_transactions", :force => true do |t|
    t.string   "eft_trace_number_ed"
    t.string   "eft_trace_number_eda"
    t.string   "eft_date"
    t.string   "eft_payment_amount"
    t.string   "payment_format_code"
    t.string   "receivers_name"
    t.string   "payer_name"
    t.string   "batch_number"
    t.integer  "ach_file_id"
    t.string   "status"
    t.integer  "aba_dda_lookup_id"
    t.string   "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crosswalks", :force => true do |t|
    t.integer  "client_id"
    t.integer  "facility_id"
    t.integer  "payer_id"
    t.integer  "hipaa_code_id",                     :null => false
    t.string   "crosswalk_hipaa_code", :limit => 5, :null => false
    t.date     "created_date"
    t.date     "updated_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crosswalks", ["client_id"], :name => "index_crosswalks_on_client_id"
  add_index "crosswalks", ["facility_id"], :name => "index_crosswalks_on_facility_id"
  add_index "crosswalks", ["payer_id"], :name => "index_crosswalks_on_payer_id"

  create_table "data_files", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_name"
  end

  create_table "default_codes_for_adjustment_reasons", :force => true do |t|
    t.string   "adjustment_reason", :limit => 20
    t.string   "group_code",        :limit => 45
    t.integer  "facility_id"
    t.integer  "hipaa_code_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enable_crosswalk",                :default => true
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"

  create_table "deleted_image_details_temps", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "folder_name"
    t.string   "image_file_name"
    t.string   "image_folder_path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "filename"
    t.binary   "content",    :limit => 16777215
    t.string   "file_type"
    t.integer  "client_id"
    t.datetime "created_at"
  end

  add_index "documents", ["client_id"], :name => "fk_document_client_id"

  create_table "environment_variables", :force => true do |t|
    t.string  "name"
    t.integer "value"
    t.text    "description"
  end

  create_table "environments", :force => true do |t|
    t.string  "name"
    t.integer "value"
    t.text    "description"
  end

  create_table "eob_errors", :force => true do |t|
    t.string  "error_type"
    t.string  "field_name"
    t.integer "severity"
    t.string  "code"
  end

  create_table "eob_qa_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "eob_qas", :force => true do |t|
    t.integer  "processor_id"
    t.integer  "qa_id"
    t.integer  "job_id"
    t.datetime "time_of_rejection"
    t.string   "account_number"
    t.integer  "total_fields"
    t.integer  "total_incorrect_fields"
    t.string   "status"
    t.integer  "total_qa_checked"
    t.string   "comment"
    t.integer  "eob_error_id"
    t.string   "payer"
    t.string   "prev_status"
    t.integer  "accuracy"
    t.integer  "eob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eob_type_id",            :default => 1
  end

  add_index "eob_qas", ["eob_error_id"], :name => "fk_eob_error_id"
  add_index "eob_qas", ["job_id"], :name => "eob_qas_idfk_1"
  add_index "eob_qas", ["qa_id"], :name => "fk_eob_qas_users_id"

  create_table "eob_reports", :force => true do |t|
    t.datetime "verify_time"
    t.string   "processor"
    t.integer  "accuracy"
    t.string   "qa"
    t.datetime "batch_date"
    t.integer  "total_fields"
    t.integer  "incorrect_fields"
    t.string   "error_type"
    t.integer  "error_severity"
    t.string   "error_code"
    t.string   "status"
    t.string   "payer"
  end

  add_index "eob_reports", ["processor"], :name => "index_eob_reports_on_processor"
  add_index "eob_reports", ["qa"], :name => "index_eob_reports_on_qa"

  create_table "eobrates", :force => true do |t|
    t.integer "high"
    t.integer "medium"
    t.integer "low"
    t.integer "client_id"
  end

  add_index "eobrates", ["client_id"], :name => "eobrates_idfk_1"

  create_table "eobs_output_activity_logs", :force => true do |t|
    t.integer "output_activity_log_id"
    t.integer "insurance_payment_eob_id"
    t.integer "patient_pay_eob_id"
  end

  create_table "era_checks", :force => true do |t|
    t.string   "transaction_hash"
    t.integer  "era_id"
    t.string   "tracking_number"
    t.string   "835_single_location"
    t.string   "status"
    t.string   "transaction_set_control_number",      :limit => 9
    t.string   "transaction_handling_code",           :limit => 2
    t.decimal  "check_amount",                                      :precision => 18, :scale => 2
    t.string   "credit_debit_flag",                   :limit => 1
    t.string   "payment_method",                      :limit => 3
    t.string   "payment_format_code",                 :limit => 10
    t.string   "payer_routing_qualifier",             :limit => 2
    t.string   "aba_routing_number",                  :limit => 12
    t.string   "payer_account_qualifier",             :limit => 3
    t.string   "payer_account_number",                :limit => 35
    t.string   "payer_company_identifier",            :limit => 10
    t.string   "payer_company_supplemental_code",     :limit => 9
    t.string   "site_routing_qualifier",              :limit => 2
    t.string   "site_routing_number",                 :limit => 12
    t.string   "site_account_qualifier",              :limit => 3
    t.string   "site_account_number",                 :limit => 35
    t.date     "check_date"
    t.string   "check_number",                        :limit => 50
    t.string   "trn_payer_company_identifier",        :limit => 10
    t.string   "trn_payer_company_supplemental_code", :limit => 50
    t.string   "site_receiver_identification",        :limit => 50
    t.date     "production_date"
    t.string   "payer_name",                          :limit => 60
    t.string   "payer_npi",                           :limit => 80
    t.string   "payer_address_1",                     :limit => 55
    t.string   "payer_address_2",                     :limit => 55
    t.string   "payer_city",                          :limit => 30
    t.string   "payer_state",                         :limit => 2
    t.string   "payer_zip",                           :limit => 15
    t.string   "era_payid_qualifier",                 :limit => 2
    t.string   "era_payid",                           :limit => 50
    t.string   "era_misc_check_segments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payer_id"
    t.string   "era_naic_id",                         :limit => 50
  end

  add_index "era_checks", ["era_id"], :name => "FK_era_checks_era"
  add_index "era_checks", ["payer_id"], :name => "FK_era_checks_payer"

  create_table "era_exceptions", :force => true do |t|
    t.string   "process"
    t.string   "code"
    t.text     "description"
    t.integer  "era_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "era_exceptions", ["era_id"], :name => "FK_era_exception_era"

  create_table "era_jobs", :force => true do |t|
    t.string   "tracking_number"
    t.integer  "era_id"
    t.string   "transaction_hash"
    t.integer  "era_check_id"
    t.string   "status"
    t.integer  "client_id"
    t.integer  "facility_id"
    t.string   "payee_name",                 :limit => 60
    t.string   "payee_qualifier",            :limit => 2
    t.string   "payee_npi",                  :limit => 80
    t.string   "payee_tin",                  :limit => 80
    t.string   "payee_planID",               :limit => 80
    t.string   "payee_address_1",            :limit => 55
    t.string   "payee_address_2",            :limit => 55
    t.string   "payee_city",                 :limit => 30
    t.string   "payee_state",                :limit => 2
    t.string   "payee_zip",                  :limit => 15
    t.string   "era_addl_payeeid_qualifier", :limit => 2
    t.string   "era_addl_payeeid",           :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "era_jobs", ["client_id"], :name => "index_era_jobs_on_client_id"
  add_index "era_jobs", ["era_check_id"], :name => "index_era_jobs_on_era_check_id"
  add_index "era_jobs", ["era_id"], :name => "index_era_jobs_on_era_id"
  add_index "era_jobs", ["facility_id"], :name => "index_era_jobs_on_facility_id"

  create_table "era_provider_adjustments", :force => true do |t|
    t.integer  "era_check_id",                                                                  :null => false
    t.string   "provider_identifier",              :limit => 50,                                :null => false
    t.date     "fiscal_period_date",                                                            :null => false
    t.string   "provider_adjustment_reason_code1", :limit => 2,                                 :null => false
    t.string   "provider_adjustment_identifier1",  :limit => 50
    t.decimal  "provider_adjustment_amount1",                    :precision => 18, :scale => 2, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "era_provider_adjustments", ["era_check_id"], :name => "index_era_provider_adjustments_on_era_check_id"

  create_table "eras", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_md5_hash"
    t.string   "sftp_location"
    t.string   "identifier_hash"
    t.datetime "xml_conversion_time"
    t.integer  "is_duplicate"
    t.integer  "parent_era_id"
    t.datetime "era_parse_start_time"
    t.datetime "era_process_start_time"
    t.datetime "era_parse_end_time"
    t.datetime "era_process_end_time"
    t.integer  "inbound_file_information_id"
    t.string   "batchid"
  end

  add_index "eras", ["inbound_file_information_id"], :name => "FK_eras_inbound_file"

  create_table "error_popups", :force => true do |t|
    t.text    "comment"
    t.integer "facility_id"
    t.date    "start_date"
    t.date    "end_date"
    t.integer "processor_id"
    t.string  "Question"
    t.string  "choice1"
    t.string  "choice2"
    t.string  "choice3"
    t.string  "answer"
    t.string  "field_id"
    t.integer "parent_id"
    t.integer "reason_code_set_name_id"
    t.integer "client_id"
    t.integer "data_file_id"
  end

  add_index "error_popups", ["facility_id"], :name => "error_popups_idfk_1"

  create_table "facilities", :force => true do |t|
    t.string   "name"
    t.text     "details"
    t.integer  "client_id"
    t.string   "sitecode"
    t.string   "facility_tin"
    t.string   "facility_npi"
    t.integer  "image_type",                                                                                   :default => 0
    t.string   "address_one"
    t.string   "address_two"
    t.string   "zip_code"
    t.string   "city"
    t.string   "state"
    t.string   "lockbox_number"
    t.string   "abbr_name"
    t.string   "tat"
    t.string   "processing_location"
    t.string   "production_status"
    t.string   "image_file_format"
    t.string   "image_processing_type"
    t.string   "index_file_format"
    t.string   "index_file_parser_type"
    t.string   "batch_load_type"
    t.string   "ocr_tolerance"
    t.string   "non_ocr_tolerance"
    t.string   "claim_file_parser_type"
    t.string   "commercial_payerid"
    t.string   "patient_payerid"
    t.string   "patient_pay_format"
    t.string   "plan_type"
    t.string   "default_service_date"
    t.string   "default_account_number"
    t.string   "default_cpt_code"
    t.string   "default_ref_number"
    t.string   "default_patient_name"
    t.boolean  "is_check_date_as_batch_date",                                                                  :default => false
    t.decimal  "average_insurance_eob_processing_productivity",                 :precision => 10, :scale => 6
    t.decimal  "average_patient_pay_eob_processing_productivity",               :precision => 10, :scale => 6
    t.boolean  "is_deleted",                                                                                   :default => false
    t.string   "client_dda_number"
    t.string   "supplemental_outputs"
    t.string   "default_insurance_payer_tin"
    t.string   "default_patpay_payer_tin"
    t.string   "lockbox_location_code",                           :limit => 5
    t.string   "lockbox_location_name"
    t.string   "group_code",                                      :limit => 10
    t.boolean  "enable_crosswalk"
    t.integer  "claim_file_count_for_mon"
    t.integer  "claim_file_count_for_tue"
    t.integer  "claim_file_count_for_wed"
    t.integer  "claim_file_count_for_thu"
    t.integer  "claim_file_count_for_fri"
    t.integer  "claim_file_count_for_sat"
    t.integer  "claim_file_count_for_sun"
    t.string   "mpi_search_type"
    t.integer  "file_arrival_threshold",                          :limit => 8,                                 :default => 1
    t.integer  "expected_files_per_day"
    t.boolean  "enable_cr",                                                                                    :default => false
    t.boolean  "ocr_enabled_flag"
    t.boolean  "batch_upload_check",                                                                           :default => false
    t.boolean  "enabled_for_user_dashboard",                                                                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "incoming_image_type"
    t.integer  "archive_claims_in"
  end

  add_index "facilities", ["client_id"], :name => "fk_client_id"
  add_index "facilities", ["sitecode"], :name => "facilities_sitecode_index", :unique => true

  create_table "facilities_codes", :force => true do |t|
    t.integer  "facility_id"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facilities_micr_informations", :force => true do |t|
    t.integer  "facility_id"
    t.integer  "micr_line_information_id"
    t.string   "onbase_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "facilities_micr_informations", ["facility_id"], :name => "index_facilities_micr_informations_on_facility_id"
  add_index "facilities_micr_informations", ["micr_line_information_id"], :name => "index_facilities_micr_informations_on_micr_line_information_id"

  create_table "facilities_npi_and_tins", :force => true do |t|
    t.integer  "facility_id"
    t.string   "npi"
    t.string   "tin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facilities_payers_informations", :force => true do |t|
    t.integer  "facility_id"
    t.integer  "payer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "in_patient_payment_code",    :limit => 25
    t.string   "out_patient_payment_code",   :limit => 25
    t.string   "in_patient_allowance_code",  :limit => 25
    t.string   "out_patient_allowance_code", :limit => 25
    t.string   "capitation_code",            :limit => 25
    t.string   "output_payid"
    t.string   "payid"
    t.string   "payer"
    t.integer  "client_id"
  end

  add_index "facilities_payers_informations", ["facility_id"], :name => "index_facilities_payers_informations_on_facility_id"
  add_index "facilities_payers_informations", ["payer_id"], :name => "index_facilities_payers_informations_on_payer_id"

  create_table "facilities_users", :force => true do |t|
    t.integer "facility_id"
    t.integer "user_id"
    t.boolean "eligible_for_auto_allocation", :default => false
    t.integer "eobs_processed",               :default => 0
  end

  add_index "facilities_users", ["facility_id"], :name => "index_facilities_users_on_facility_id"
  add_index "facilities_users", ["user_id"], :name => "index_facilities_users_on_user_id"

  create_table "facility_cut_relationships", :force => true do |t|
    t.integer  "facility_id"
    t.string   "cut"
    t.string   "day"
    t.datetime "time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "expected_day_of_arrival"
    t.string   "lockbox_number"
  end

  create_table "facility_lockbox_mappings", :force => true do |t|
    t.integer  "facility_id"
    t.string   "lockbox_number"
    t.string   "lockbox_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "lockbox_code"
    t.string   "tin"
    t.string   "npi"
    t.string   "payee_name"
    t.string   "address_one"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
  end

  create_table "facility_lookup_fields", :force => true do |t|
    t.string  "name"
    t.string  "lookup_type"
    t.string  "value"
    t.string  "category"
    t.string  "sub_category", :limit => 60
    t.integer "sort_order"
  end

  create_table "facility_output_configs", :force => true do |t|
    t.integer  "facility_id"
    t.string   "eob_type"
    t.boolean  "separate_payment_and_correspondence",                         :default => false
    t.string   "grouping"
    t.string   "format"
    t.boolean  "multi_transaction",                                           :default => false
    t.string   "file_name"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "predefined_payer"
    t.string   "report_type",                                   :limit => 50
    t.boolean  "separate_insurance_and_pat_pay",                              :default => false
    t.string   "content_layout"
    t.boolean  "quotes_configuration",                                        :default => false
    t.string   "zip_file_name"
    t.text     "operation_log_config"
    t.string   "other_output_type"
    t.string   "file_name_corr"
    t.string   "required_claim_types"
    t.boolean  "payment_corres_patpay_in_one_file",                           :default => false
    t.boolean  "payment_corres_in_one_patpay_in_separate_file",               :default => true
    t.string   "folder_name"
    t.boolean  "payment_patpay_in_one_corres_in_separate_file",               :default => false
    t.string   "nextgen_folder_name"
    t.string   "nextgen_file_name"
    t.string   "nextgen_zip_file_name"
  end

  create_table "facility_specific_payees", :force => true do |t|
    t.integer  "facility_id",          :null => false
    t.integer  "client_id",            :null => false
    t.string   "db_identifier"
    t.string   "xpeditor_client_code", :null => false
    t.string   "payee_name",           :null => false
    t.string   "payer_type"
    t.string   "match_criteria"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "weightage"
  end

  create_table "facility_specific_payers", :force => true do |t|
    t.string   "payid"
    t.string   "payer"
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payer_id"
    t.integer  "client_id"
    t.string   "output_payid"
  end

  create_table "facility_specific_payers_obsolete", :force => true do |t|
    t.string   "payid"
    t.string   "payer"
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payer_id"
    t.integer  "client_id"
    t.string   "output_payid"
  end

  create_table "file837_informations", :force => true do |t|
    t.string   "zip_file_name"
    t.string   "facility"
    t.string   "file_837_name"
    t.datetime "arrival_time"
    t.float    "size"
    t.datetime "load_start_time"
    t.datetime "load_end_time"
    t.string   "status"
    t.integer  "total_claim_count"
    t.integer  "loaded_claim_count"
    t.integer  "total_svcline_count"
    t.integer  "loaded_svcline_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hipaa_codes", :force => true do |t|
    t.string   "hipaa_adjustment_code"
    t.string   "hipaa_code_description", :limit => 2000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active_indicator",                       :default => true
  end

  create_table "hlsc_qas", :force => true do |t|
    t.integer "batch_id"
    t.integer "user_id"
    t.integer "total_eobs"
    t.integer "rejected_eobs"
  end

  add_index "hlsc_qas", ["batch_id"], :name => "hlsc_qas_idfk_1"
  add_index "hlsc_qas", ["user_id"], :name => "hlsc_qas_idfk_2"

  create_table "idle_processors", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "idle_processors", ["user_id"], :name => "by_user_id"

  create_table "image_types", :force => true do |t|
    t.string   "image_type",               :limit => 3
    t.string   "patient_account_number",   :limit => 30
    t.string   "patient_last_name",        :limit => 35
    t.string   "patient_first_name",       :limit => 35
    t.integer  "image_page_number"
    t.integer  "images_for_job_id"
    t.integer  "insurance_payment_eob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "image_types", ["images_for_job_id"], :name => "index_image_types_on_images_for_job_id"
  add_index "image_types", ["insurance_payment_eob_id"], :name => "index_image_types_on_insurance_payment_eob_id"

  create_table "images_for_jobs", :force => true do |t|
    t.string   "image_content_type"
    t.string   "image_file_name"
    t.integer  "image_file_size"
    t.integer  "width"
    t.integer  "height"
    t.string   "eob_status",         :default => "New"
    t.integer  "batch_id"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_number"
    t.string   "transaction_type"
    t.integer  "page_count"
    t.datetime "image_updated_at"
  end

  add_index "images_for_jobs", ["batch_id"], :name => "images_for_jobs_idfk_1"

  create_table "inbound_file_informations", :force => true do |t|
    t.string   "name"
    t.integer  "size"
    t.datetime "arrival_time"
    t.datetime "load_start_time"
    t.datetime "load_end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "estimated_load_end_time"
    t.string   "file_type"
    t.string   "status"
    t.integer  "facility_id"
    t.integer  "count"
    t.string   "secondary_status",        :limit => 64
    t.date     "arrival_date"
    t.string   "file_path"
    t.string   "cut",                     :limit => 64
    t.decimal  "total_charge",                           :precision => 10, :scale => 2
    t.decimal  "total_excluded_charge",                  :precision => 10, :scale => 2
    t.date     "batchdate"
    t.datetime "expected_arrival_date"
    t.datetime "expected_start_time"
    t.datetime "expected_end_time"
    t.integer  "revremit_exception_id"
    t.string   "lockbox_number",          :limit => 50
    t.string   "lockbox_name",            :limit => 100
    t.datetime "effective_tat_date"
    t.integer  "is_nullfile",             :limit => 1,                                  :default => 0
  end

  create_table "insurance_payment_eobs", :force => true do |t|
    t.integer  "check_information_id"
    t.string   "patient_account_number",                       :limit => 30
    t.string   "claim_number",                                 :limit => 30
    t.string   "claim_status_code",                            :limit => 2
    t.decimal  "total_submitted_charge_for_claim",                           :precision => 10, :scale => 2
    t.decimal  "total_amount_paid_for_claim",                                :precision => 10, :scale => 2
    t.decimal  "total_primary_payer_amount",                                 :precision => 10, :scale => 2
    t.decimal  "total_co_insurance",                                         :precision => 10, :scale => 2
    t.decimal  "total_deductible",                                           :precision => 10, :scale => 2
    t.decimal  "total_co_pay",                                               :precision => 10, :scale => 2
    t.decimal  "total_non_covered",                                          :precision => 10, :scale => 2
    t.decimal  "total_discount",                                             :precision => 10, :scale => 2
    t.decimal  "total_allowable",                                            :precision => 10, :scale => 2
    t.decimal  "total_service_balance",                                      :precision => 10, :scale => 2
    t.integer  "claim_indicator_code",                         :limit => 2
    t.decimal  "claim_interest",                                             :precision => 10, :scale => 2
    t.string   "transaction_reference_identification_number",  :limit => 30
    t.string   "drg_code",                                     :limit => 3
    t.decimal  "drg_weight",                                                 :precision => 10, :scale => 2
    t.decimal  "percent",                                                    :precision => 10, :scale => 2
    t.string   "claim_adjustment_group_code",                  :limit => 2
    t.string   "claim_adjustment_reason_code",                 :limit => 5
    t.string   "claim_adjustment_reason_code_description",     :limit => 50
    t.string   "claim_reason_code_number",                     :limit => 5
    t.string   "claim_reason_code_description",                :limit => 50
    t.integer  "units_of_service_being_adjusted"
    t.string   "patient_last_name",                            :limit => 35
    t.string   "patient_first_name",                           :limit => 35
    t.string   "patient_middle_initial",                       :limit => 4
    t.string   "patient_suffix",                               :limit => 4
    t.string   "patient_identification_code_qualifier",        :limit => 20
    t.string   "patient_identification_code",                  :limit => 80
    t.string   "subscriber_last_name",                         :limit => 35
    t.string   "subscriber_first_name",                        :limit => 35
    t.string   "subscriber_middle_initial",                    :limit => 4
    t.string   "subscriber_suffix",                            :limit => 4
    t.integer  "subscriber_identification_code_qualifier",     :limit => 2
    t.string   "subscriber_identification_code",               :limit => 80
    t.string   "rendering_provider_last_name",                 :limit => 35
    t.string   "rendering_provider_first_name",                :limit => 35
    t.string   "rendering_provider_suffix",                    :limit => 5
    t.string   "rendering_provider_middle_initial",            :limit => 4
    t.string   "rendering_provider_identification_number",     :limit => 20
    t.integer  "rendering_provider_code_qualifier"
    t.date     "provider_date"
    t.string   "provider_adjustment_reason_code",              :limit => 20
    t.string   "provider_adjustment_amount",                   :limit => 20
    t.string   "provider_tin",                                 :limit => 20
    t.string   "claim_type"
    t.string   "plan_type",                                    :limit => 20
    t.string   "provider_npi",                                 :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
    t.decimal  "claim_adjustment_charges",                                   :precision => 10, :scale => 2
    t.string   "claim_charges_reasoncode"
    t.string   "claim_charge_groupcode"
    t.decimal  "claim_adjustment_non_covered",                               :precision => 10, :scale => 2
    t.string   "claim_noncovered_reasoncode"
    t.string   "claim_noncovered_groupcode"
    t.decimal  "claim_adjustment_discount",                                  :precision => 10, :scale => 2
    t.string   "claim_discount_reasoncode"
    t.string   "claim_discount_groupcode"
    t.decimal  "claim_adjustment_contractual_amount",                        :precision => 10, :scale => 2
    t.string   "claim_contractual_reasoncode"
    t.string   "claim_contractual_groupcode"
    t.decimal  "claim_adjustment_co_insurance",                              :precision => 10, :scale => 2
    t.string   "claim_coinsurance_reasoncode"
    t.string   "claim_coinsurance_groupcode"
    t.decimal  "claim_adjustment_deductable",                                :precision => 10, :scale => 2
    t.string   "claim_deductable_reasoncode"
    t.string   "claim_deductuble_groupcode"
    t.decimal  "claim_adjustment_copay",                                     :precision => 10, :scale => 2
    t.string   "claim_copay_reasoncode"
    t.string   "claim_copay_groupcode"
    t.decimal  "claim_adjustment_payment",                                   :precision => 10, :scale => 2
    t.string   "claim_payment_reasoncode"
    t.string   "claim_payment_groupcode"
    t.decimal  "claim_adjustment_primary_pay_payment",                       :precision => 10, :scale => 2
    t.string   "claim_primary_payment_reasoncode"
    t.string   "claim_primary_payment_groupcode"
    t.string   "claim_charges_reasoncode_description"
    t.string   "claim_noncovered_reasoncode_description"
    t.string   "claim_discount_reasoncode_description"
    t.string   "claim_contractual_reasoncode_description"
    t.string   "claim_coinsurance_reasoncode_description"
    t.string   "claim_deductable_reasoncode_description"
    t.string   "claim_copay_reasoncode_description"
    t.string   "claim_payment_reasoncode_description"
    t.string   "claim_primary_payment_reasoncode_description"
    t.decimal  "total_contractual_amount",                                   :precision => 10, :scale => 2
    t.string   "provider_organisation"
    t.string   "insurance_policy_number"
    t.string   "eob_regenerate"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "sub_job_id"
    t.string   "patient_type"
    t.string   "hcra"
    t.string   "facility_type_code"
    t.integer  "processor_id"
    t.integer  "qa_id"
    t.date     "processing_completed"
    t.integer  "image_page_no"
    t.date     "claim_from_date"
    t.date     "claim_to_date"
    t.decimal  "late_filing_charge",                                         :precision => 10, :scale => 2
    t.decimal  "total_expected_payment",                                     :precision => 10, :scale => 2
    t.string   "patient_medistreams_id"
    t.decimal  "total_denied",                                               :precision => 10, :scale => 2
    t.string   "claim_denied_reasoncode"
    t.string   "claim_denied_groupcode"
    t.string   "claim_denied_reasoncode_description"
    t.integer  "claim_information_id"
    t.date     "date_received_by_insurer"
    t.string   "carrier_code",                                 :limit => 15
    t.string   "category",                                                                                  :default => "service"
    t.integer  "processor_input_fields"
    t.integer  "image_page_to_number"
    t.string   "rejection_comment",                            :limit => 70
    t.integer  "contact_information_id"
    t.decimal  "total_drg_amount",                                           :precision => 10, :scale => 2
    t.string   "payer_control_number",                         :limit => 50
    t.string   "marital_status",                               :limit => 15
    t.string   "secondary_plan_code",                          :limit => 15
    t.string   "tertiary_plan_code",                           :limit => 15
    t.string   "state_use_only",                               :limit => 30
    t.decimal  "fund",                                                       :precision => 10, :scale => 2
    t.decimal  "total_retention_fees",                                       :precision => 10, :scale => 2
    t.decimal  "total_pbid",                                                 :precision => 10, :scale => 2
    t.integer  "copay_reason_code_id"
    t.integer  "coinsurance_reason_code_id"
    t.integer  "contractual_reason_code_id"
    t.integer  "deductible_reason_code_id"
    t.integer  "denied_reason_code_id"
    t.integer  "discount_reason_code_id"
    t.integer  "noncovered_reason_code_id"
    t.integer  "primary_payment_reason_code_id"
    t.string   "balance_record_type",                          :limit => 25
    t.string   "guid",                                         :limit => 36
    t.string   "payer_indicator",                              :limit => 10
    t.integer  "total_edited_fields"
    t.string   "document_classification",                      :limit => 50
    t.string   "claim_payid",                                  :limit => 60
    t.datetime "svc_start_time"
    t.string   "archived_claim_hash"
    t.decimal  "over_payment_recovery",                                      :precision => 10, :scale => 2
    t.decimal  "total_prepaid",                                              :precision => 10, :scale => 2
    t.string   "total_plan_coverage",                          :limit => 5
    t.integer  "prepaid_reason_code_id"
    t.integer  "place_of_service"
    t.boolean  "statement_applied"
    t.boolean  "multiple_invoice_applied"
    t.boolean  "multiple_statement_applied"
    t.string   "statement_receiver",                           :limit => 15
    t.integer  "uid"
    t.decimal  "total_patient_responsibility",                               :precision => 10, :scale => 2
    t.integer  "pr_reason_code_id"
    t.string   "medical_record_number",                        :limit => 50
    t.string   "key"
    t.string   "category_action"
    t.string   "reason"
    t.date     "letter_date"
    t.string   "payee_type_format",                            :limit => 1
  end

  add_index "insurance_payment_eobs", ["check_information_id"], :name => "insurance_payment_eobs_idfk_1"
  add_index "insurance_payment_eobs", ["processing_completed"], :name => "index_insurance_payment_eobs_on_processing_completed"
  add_index "insurance_payment_eobs", ["processor_id"], :name => "index_insurance_payment_eobs_on_processor_id"
  add_index "insurance_payment_eobs", ["sub_job_id"], :name => "index_insurance_payment_eobs_on_sub_job_id"

  create_table "insurance_payment_eobs_ansi_remark_codes", :force => true do |t|
    t.integer  "insurance_payment_eob_id", :null => false
    t.integer  "ansi_remark_code_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "insurance_payment_eobs_ansi_remark_codes", ["ansi_remark_code_id"], :name => "by_ansi_remark_code_id"
  add_index "insurance_payment_eobs_ansi_remark_codes", ["insurance_payment_eob_id"], :name => "by_insurance_payment_eob_id"

  create_table "insurance_payment_eobs_reason_codes", :force => true do |t|
    t.integer  "insurance_payment_eob_id"
    t.integer  "reason_code_id"
    t.string   "adjustment_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "insurance_payment_eras", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "era_check_id"
    t.string   "patient_account_number",                   :limit => 38
    t.string   "claim_status_code"
    t.decimal  "total_submitted_charge_for_claim",                       :precision => 18, :scale => 2
    t.decimal  "total_amount_paid_for_claim",                            :precision => 18, :scale => 2
    t.decimal  "total_patient_responsibility",                           :precision => 18, :scale => 2
    t.string   "claim_indicator_code",                     :limit => 2
    t.string   "claim_number",                             :limit => 50
    t.string   "facility_type_code",                       :limit => 2
    t.string   "claim_frequency_code",                     :limit => 1
    t.string   "drg_code",                                 :limit => 4
    t.integer  "drg_weight"
    t.decimal  "discharge_fraction",                                     :precision => 10, :scale => 2
    t.string   "patient_entity_qualifier",                 :limit => 1
    t.string   "patient_last_name",                        :limit => 60
    t.string   "patient_first_name",                       :limit => 35
    t.string   "patient_middle_initial",                   :limit => 25
    t.string   "patient_suffix",                           :limit => 10
    t.string   "patient_identification_code_qualifier",    :limit => 2
    t.string   "patient_identification_code",              :limit => 80
    t.string   "subscriber_entity_qualifier",              :limit => 1
    t.string   "subscriber_last_name",                     :limit => 60
    t.string   "subscriber_first_name",                    :limit => 35
    t.string   "subscriber_middle_initial",                :limit => 25
    t.string   "subscriber_suffix",                        :limit => 10
    t.string   "subscriber_identification_code_qualifier", :limit => 2
    t.string   "subscriber_identification_code",           :limit => 80
    t.string   "rendering_provider_entity_qualifier",      :limit => 1
    t.string   "rendering_provider_last_name",             :limit => 60
    t.string   "rendering_provider_first_name",            :limit => 35
    t.string   "rendering_provider_middle_initial",        :limit => 25
    t.string   "rendering_provider_suffix",                :limit => 10
    t.string   "rendering_provider_code_qualifier",        :limit => 2
    t.string   "rendering_provider_identification_number", :limit => 80
    t.string   "other_claim_identification_qualifier",     :limit => 3
    t.string   "other_claim_identifier",                   :limit => 50
    t.date     "claim_from_date"
    t.date     "claim_to_date"
    t.date     "date_received_by_insurer"
    t.string   "amt_qualifier",                            :limit => 3
    t.decimal  "amt_amount",                                             :precision => 18, :scale => 2
    t.string   "archived_claim_hash"
    t.decimal  "claim_adjustment_primary_pay_payment",                   :precision => 18, :scale => 2
    t.string   "claim_primary_payment_reasoncode",         :limit => 5
    t.string   "claim_primary_payment_groupcode",          :limit => 2
    t.decimal  "claim_adjustment_co_insurance",                          :precision => 18, :scale => 2
    t.string   "claim_coinsurance_reasoncode",             :limit => 5
    t.string   "claim_coinsurance_groupcode",              :limit => 2
    t.decimal  "claim_adjustment_deductible",                            :precision => 18, :scale => 2
    t.string   "claim_deductible_reasoncode",              :limit => 5
    t.string   "claim_deductible_groupcode",               :limit => 2
    t.decimal  "claim_adjustment_copay",                                 :precision => 18, :scale => 2
    t.string   "claim_copay_reasoncode",                   :limit => 5
    t.string   "claim_copay_groupcode",                    :limit => 2
    t.decimal  "claim_adjustment_non_covered",                           :precision => 18, :scale => 2
    t.string   "claim_noncovered_reasoncode",              :limit => 5
    t.string   "claim_noncovered_groupcode",               :limit => 2
    t.decimal  "claim_adjustment_discount",                              :precision => 18, :scale => 2
    t.string   "claim_discount_reasoncode",                :limit => 5
    t.string   "claim_discount_groupcode",                 :limit => 2
    t.decimal  "claim_adjustment_contractual_amount",                    :precision => 18, :scale => 2
    t.string   "claim_contractual_reasoncode",             :limit => 5
    t.string   "claim_contractual_groupcode",              :limit => 2
    t.decimal  "total_denied",                                           :precision => 18, :scale => 2
    t.string   "claim_denied_reasoncode",                  :limit => 5
    t.string   "claim_denied_groupcode",                   :limit => 2
    t.integer  "lx_number"
    t.string   "ts3_provider_number",                      :limit => 60
    t.integer  "ts3_facility_type_code"
    t.date     "ts3_date"
    t.integer  "ts3_quantity"
    t.decimal  "ts3_amount",                                             :precision => 18, :scale => 2
    t.string   "era_misc_claim_segments"
  end

  add_index "insurance_payment_eras", ["era_check_id"], :name => "FK_ins_pay_eras_era_check"

  create_table "isa_identifiers", :force => true do |t|
    t.integer "isa_number"
  end

  create_table "job_activity_logs", :force => true do |t|
    t.integer  "job_id"
    t.integer  "processor_id"
    t.integer  "qa_id"
    t.integer  "allocated_user_id"
    t.string   "activity"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "eob_id"
    t.integer  "eob_type_id"
  end

  add_index "job_activity_logs", ["activity"], :name => "idx_jal_activity"
  add_index "job_activity_logs", ["eob_id"], :name => "idx_job_activity_logs_eob_id"
  add_index "job_activity_logs", ["eob_type_id"], :name => "idx_jal_eob_type_id"
  add_index "job_activity_logs", ["job_id"], :name => "index_job_activity_logs_on_job_id"
  add_index "job_activity_logs", ["processor_id"], :name => "idx_jal_processor_id"
  add_index "job_activity_logs", ["qa_id"], :name => "idx_jal_qa_id"

  create_table "job_rejection_comments", :force => true do |t|
    t.string "comment"
  end

  create_table "job_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "jobs", :force => true do |t|
    t.integer  "batch_id"
    t.string   "check_number"
    t.string   "tiff_number"
    t.integer  "count",                                                                     :default => 0
    t.string   "processor_status",                                                          :default => "NEW"
    t.datetime "processor_flag_time"
    t.datetime "processor_target_time"
    t.datetime "qa_flag_time"
    t.datetime "qa_target_time"
    t.text     "details"
    t.integer  "qa_id"
    t.integer  "processor_id"
    t.integer  "payer_id"
    t.decimal  "estimated_eob",                              :precision => 10, :scale => 2
    t.integer  "adjusted_eob"
    t.integer  "image_count"
    t.string   "comment"
    t.string   "job_status",                                                                :default => "NEW"
    t.string   "qa_status",                                                                 :default => "NEW"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.datetime "created_at"
    t.string   "comment_for_qa"
    t.integer  "rejections",                                                                :default => 0
    t.integer  "incomplete_count",                                                          :default => 0
    t.string   "incomplete_tiff"
    t.datetime "work_queue_flagtime"
    t.string   "processor_comments",                                                        :default => "null"
    t.string   "rejected_comment"
    t.string   "qa_comment"
    t.integer  "pages_from"
    t.integer  "pages_to"
    t.integer  "images_for_job_id"
    t.integer  "parent_job_id"
    t.datetime "output_835_generated_time"
    t.text     "client_specific_fields"
    t.integer  "split_parent_job_id"
    t.string   "tiff_images"
    t.string   "transaction_number"
    t.boolean  "is_ocr"
    t.datetime "ocr_arrival_time"
    t.string   "ocr_status"
    t.integer  "total_ocr_fields"
    t.integer  "total_high_confidence_fields"
    t.integer  "total_edited_fields"
    t.integer  "starting_page_number",                                                      :default => 0
    t.datetime "ocr_file_sent_time"
    t.datetime "ocr_expected_arrival_time"
    t.datetime "ocr_file_arrived_time"
    t.string   "payer_group",                  :limit => 15,                                :default => "--",   :null => false
    t.string   "lockbox",                      :limit => 20
  end

  add_index "jobs", ["batch_id"], :name => "index_jobs_on_batch_id"
  add_index "jobs", ["parent_job_id"], :name => "index_jobs_on_parent_job_id"
  add_index "jobs", ["processor_id"], :name => "index_jobs_on_processor_id"
  add_index "jobs", ["processor_status"], :name => "index_jobs_on_processor_status"
  add_index "jobs", ["qa_id"], :name => "index_jobs_on_qa_id"
  add_index "jobs", ["qa_status"], :name => "index_jobs_on_qa_status"

  create_table "meta_batch_informations", :force => true do |t|
    t.string   "document_format"
    t.datetime "due_time"
    t.integer  "priority"
    t.string   "provider_code"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "micr_line_informations", :force => true do |t|
    t.string   "aba_routing_number",   :limit => 9
    t.string   "payer_account_number", :limit => 15
    t.integer  "payer_id"
    t.string   "status",                             :default => "New"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payid_temp",           :limit => 10
    t.boolean  "is_ocr",                             :default => false
  end

  add_index "micr_line_informations", ["payer_id"], :name => "micr_line_informations_idfk_2"
  add_index "micr_line_informations", ["payid_temp"], :name => "index_micr_line_informations_on_payid_temp"
  add_index "micr_line_informations", ["status"], :name => "index_micr_line_informations_on_status"

  create_table "misc_segments_eras", :force => true do |t|
    t.integer  "era_id"
    t.string   "segment_level",               :limit => 20
    t.string   "segment_header",              :limit => 3
    t.string   "segment_text"
    t.integer  "segment_line_number_in_file"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "misc_segments_eras", ["era_id"], :name => "FK_misc_seg_eras_era"

  create_table "mpi_statistics_reports", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "user_id"
    t.string   "mpi_status"
    t.string   "search_criteria"
    t.datetime "start_time"
    t.integer  "eob_id"
    t.string   "eob_type"
  end

  add_index "mpi_statistics_reports", ["batch_id"], :name => "mpi_statistics_reports_idfk_1"
  add_index "mpi_statistics_reports", ["eob_id"], :name => "index_mpi_statistics_reports_on_eob_id"
  add_index "mpi_statistics_reports", ["user_id"], :name => "mpi_statistics_reports_idfk_2"

  create_table "old_passwords", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.string   "password_hash", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "output_activity_logs", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "user_id"
    t.string   "activity"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "file_name"
    t.string   "file_format"
    t.string   "file_location"
    t.integer  "file_size"
    t.decimal  "total_charge",                        :precision => 10, :scale => 2
    t.decimal  "total_excluded_charge",               :precision => 10, :scale => 2
    t.datetime "estimated_end_time"
    t.string   "checksum",              :limit => 64
    t.datetime "upload_start_time"
    t.datetime "upload_end_time"
    t.string   "status",                :limit => 32
    t.decimal  "total_payment_charge",                :precision => 10, :scale => 2
  end

  add_index "output_activity_logs", ["batch_id"], :name => "index_output_activity_logs_on_batch_id"
  add_index "output_activity_logs", ["status"], :name => "index_output_activity_logs_on_status"

  create_table "output_regenerated_logs", :force => true do |t|
    t.integer  "eob_id"
    t.integer  "user_id"
    t.string   "activity"
    t.datetime "start_time"
    t.datetime "end_time"
  end

  create_table "partners", :force => true do |t|
    t.string  "name"
    t.integer "instance_id"
  end

  create_table "partners_users", :force => true do |t|
    t.integer "partner_id"
    t.integer "user_id"
  end

  add_index "partners_users", ["partner_id"], :name => "partners_users_idfk_1"
  add_index "partners_users", ["user_id"], :name => "partners_users_idfk_2"

  create_table "patient_pay_eobs", :force => true do |t|
    t.integer  "check_information_id"
    t.string   "practice_number",            :limit => 30
    t.string   "account_number",             :limit => 30
    t.date     "transaction_date"
    t.decimal  "stub_amount",                              :precision => 10, :scale => 2
    t.decimal  "check_amount",                             :precision => 10, :scale => 2
    t.decimal  "statement_amount",                         :precision => 10, :scale => 2
    t.string   "patient_last_name",          :limit => 35
    t.string   "patient_first_name",         :limit => 35
    t.string   "patient_middle_initial",     :limit => 4
    t.string   "patient_suffix",             :limit => 3
    t.string   "guarantor_last_name",        :limit => 35
    t.string   "patient_pay_eob_regenerate"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "processor_id"
    t.integer  "qa_id"
    t.date     "processing_completed"
    t.integer  "image_page_no"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "processor_input_fields"
    t.string   "document_classification",    :limit => 50
    t.integer  "job_id"
    t.integer  "uid"
  end

  add_index "patient_pay_eobs", ["check_information_id"], :name => "patient_pay_eobs_idfk_1"
  add_index "patient_pay_eobs", ["job_id"], :name => "index_patient_pay_eobs_on_job_id"

  create_table "patients", :force => true do |t|
    t.integer  "insurance_payment_eob_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "middle_initial"
    t.string   "suffix"
    t.string   "patient_identification_code_qualifier"
    t.string   "patient_account_number"
    t.string   "patient_medistreams_id"
    t.string   "address_one"
    t.string   "address_two"
    t.string   "zip_code"
    t.string   "city"
    t.string   "state"
    t.string   "insurance_policy_number"
    t.string   "patient_type"
    t.string   "subscriber_identification_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "patients", ["insurance_payment_eob_id"], :name => "index_patients_on_insurance_payment_eob_id"

  create_table "payer_exclusions", :force => true do |t|
    t.integer  "facility_id",              :null => false
    t.integer  "payer_id",                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "micr_line_information_id"
    t.string   "status"
  end

  create_table "payers", :force => true do |t|
    t.string   "gateway",                 :limit => 10
    t.string   "payid"
    t.string   "payer"
    t.string   "gr_name"
    t.text     "pay_address_one"
    t.text     "pay_address_two"
    t.text     "pay_address_three"
    t.string   "phone"
    t.text     "details"
    t.string   "payer_zip"
    t.string   "payer_state"
    t.string   "payer_city"
    t.string   "plan_type"
    t.string   "client",                                                                :default => "PEMA"
    t.string   "payment_code"
    t.string   "payer_type"
    t.string   "payer_tin"
    t.string   "hcra_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "footnote_indicator",                                                    :default => false
    t.string   "status",                  :limit => 25
    t.string   "company_id",              :limit => 10
    t.string   "gateway_temp",            :limit => 10
    t.string   "remits_gateway",          :limit => 10
    t.integer  "parent_id"
    t.string   "website",                 :limit => 200
    t.integer  "reason_code_set_name_id"
    t.decimal  "eobs_per_image",                         :precision => 10, :scale => 2
    t.datetime "batch_target_time"
    t.boolean  "is_ocr"
  end

  add_index "payers", ["payer"], :name => "index_payers_on_payer"
  add_index "payers", ["payid"], :name => "index_payers_on_payid"
  add_index "payers", ["reason_code_set_name_id"], :name => "reason_code_set_name_id"
  add_index "payers", ["reason_code_set_name_id"], :name => "reason_code_set_name_id_2"
  add_index "payers", ["status"], :name => "index_payers_on_status"

  create_table "processor_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "provider_adjustments", :force => true do |t|
    t.string   "description",              :limit => 100
    t.string   "qualifier",                :limit => 5
    t.decimal  "amount",                                  :precision => 10, :scale => 2
    t.string   "patient_account_number",   :limit => 30
    t.integer  "image_page_number"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "insurance_payment_eob_id"
  end

  create_table "providers", :force => true do |t|
    t.integer  "facility_id"
    t.string   "provider_last_name"
    t.string   "provider_first_name"
    t.string   "provider_suffix"
    t.string   "provider_middle_initial"
    t.string   "provider_npi_number"
    t.string   "provider_tin_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "providers", ["facility_id"], :name => "providers_idfk_1"

  create_table "qa_edits", :force => true do |t|
    t.string   "field_name"
    t.string   "previous_value"
    t.string   "current_value"
    t.integer  "insurance_payment_eob_id"
    t.integer  "patient_pay_eob_id"
    t.integer  "service_payment_eob_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qa_edits", ["insurance_payment_eob_id"], :name => "index_qa_edits_on_insurance_payment_eob_id"
  add_index "qa_edits", ["patient_pay_eob_id"], :name => "index_qa_edits_on_patient_pay_eob_id"
  add_index "qa_edits", ["service_payment_eob_id"], :name => "index_qa_edits_on_service_payment_eob_id"
  add_index "qa_edits", ["user_id"], :name => "index_qa_edits_on_user_id"

  create_table "qa_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "query_details", :force => true do |t|
    t.string   "criteria"
    t.string   "compare"
    t.date     "from"
    t.date     "to"
    t.datetime "created_at"
    t.string   "from_time"
    t.string   "to_time"
  end

  create_table "reason_code_set_names", :force => true do |t|
    t.string   "name",       :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reason_codes", :force => true do |t|
    t.string   "reason_code"
    t.string   "reason_code_description",    :limit => 2500
    t.string   "check_number_obsolete",      :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                     :limit => 25,   :default => "NEW"
    t.date     "learn_date"
    t.string   "unique_code",                :limit => 11
    t.integer  "reason_code_set_name_id"
    t.boolean  "marked_for_deletion",                        :default => false
    t.boolean  "active",                                     :default => true
    t.boolean  "notify",                                     :default => false
    t.integer  "replacement_reason_code_id"
    t.integer  "check_information_id"
    t.string   "check_number",               :limit => 30
    t.string   "payer_name"
    t.integer  "job_id"
    t.boolean  "remark_code_crosswalk_flag",                 :default => false
  end

  add_index "reason_codes", ["check_information_id"], :name => "fk_check_information_id"
  add_index "reason_codes", ["reason_code"], :name => "index_reason_codes_on_reason_code"
  add_index "reason_codes", ["reason_code_description"], :name => "index_reason_codes_on_reason_code_description", :length => {"reason_code_description"=>767}
  add_index "reason_codes", ["reason_code_set_name_id"], :name => "index_reason_codes_on_reason_code_set_name_id"
  add_index "reason_codes", ["replacement_reason_code_id"], :name => "index_reason_codes_on_replacement_reason_code_id"
  add_index "reason_codes", ["status", "marked_for_deletion", "active"], :name => "index_on_status_marked_for_deletion_active"
  add_index "reason_codes", ["unique_code"], :name => "index_reason_codes_on_unique_code"

  create_table "reason_codes_ansi_remark_codes", :force => true do |t|
    t.integer  "reason_code_id",                        :null => false
    t.integer  "ansi_remark_code_id",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "facility_id"
    t.integer  "client_id"
    t.boolean  "active_indicator",    :default => true
  end

  add_index "reason_codes_ansi_remark_codes", ["ansi_remark_code_id"], :name => "index_ansi_remark_code_id"
  add_index "reason_codes_ansi_remark_codes", ["client_id"], :name => "index_client_id"
  add_index "reason_codes_ansi_remark_codes", ["facility_id"], :name => "index_facility_id"

  create_table "reason_codes_clients_facilities_set_names", :force => true do |t|
    t.integer  "reason_code_id"
    t.integer  "client_id"
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "claim_status_code",        :limit => 10
    t.string   "denied_claim_status_code", :limit => 10
    t.string   "reporting_activity1",      :limit => 50
    t.string   "reporting_activity2",      :limit => 50
    t.boolean  "active_indicator",                       :default => true
    t.integer  "hipaa_code_id"
    t.integer  "denied_hipaa_code_id"
    t.string   "hipaa_group_code",         :limit => 10
    t.string   "denied_hipaa_group_code",  :limit => 10
  end

  add_index "reason_codes_clients_facilities_set_names", ["client_id"], :name => "by_client_id"
  add_index "reason_codes_clients_facilities_set_names", ["denied_hipaa_code_id"], :name => "index_denied_hipaa_code_id"
  add_index "reason_codes_clients_facilities_set_names", ["facility_id"], :name => "by_facility_id"
  add_index "reason_codes_clients_facilities_set_names", ["hipaa_code_id"], :name => "index_hipaa_code_id"
  add_index "reason_codes_clients_facilities_set_names", ["reason_code_id"], :name => "by_reason_code_id"

  create_table "reason_codes_clients_facilities_set_names_client_codes", :force => true do |t|
    t.integer  "reason_codes_clients_facilities_set_name_id",               :null => false
    t.integer  "client_code_id",                                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category",                                    :limit => 20
  end

  create_table "reason_codes_jobs", :force => true do |t|
    t.integer  "reason_code_id"
    t.integer  "parent_job_id"
    t.integer  "sub_job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "existence",      :default => true
    t.text     "details"
  end

  add_index "reason_codes_jobs", ["parent_job_id", "reason_code_id"], :name => "index_on_parent_job_id_reason_code_id", :unique => true
  add_index "reason_codes_jobs", ["sub_job_id"], :name => "index_reason_codes_jobs_on_sub_job_id"

  create_table "reasons", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reconciliation_informations", :force => true do |t|
    t.string   "index_batch_number"
    t.date     "deposit_date"
    t.string   "lockbox_number"
    t.boolean  "is_batch_loaded",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rejection_comments", :force => true do |t|
    t.string   "name"
    t.integer  "facility_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "job_status",  :default => "incomplete"
  end

  create_table "report_check_informations", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "job_id"
    t.integer  "check_information_id"
    t.integer  "image_count"
    t.decimal  "check_amount",                :precision => 10, :scale => 2
    t.decimal  "total_indexed_amount",        :precision => 10, :scale => 2
    t.integer  "total_eobs"
    t.integer  "total_eobs_with_mpi_success"
    t.integer  "total_eobs_with_mpi_failure"
    t.boolean  "is_self_pay"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_check_informations", ["batch_id"], :name => "batch_id_fk"
  add_index "report_check_informations", ["check_information_id"], :name => "check_information_id_fk"
  add_index "report_check_informations", ["job_id"], :name => "job_id_fk"

  create_table "revremit_exceptions", :force => true do |t|
    t.string   "exception_type"
    t.text     "client_exception"
    t.text     "system_exception"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "runners", :force => true do |t|
    t.datetime "imported_at"
    t.string   "imported_by"
    t.string   "imported_from"
    t.integer  "batchid"
  end

  create_table "sampling_rates", :force => true do |t|
    t.string  "slab"
    t.integer "value", :default => 5
  end

  create_table "sequences", :primary_key => "name", :force => true do |t|
    t.integer "value", :null => false
  end

  create_table "service_level_adjustments_eras", :force => true do |t|
    t.integer  "service_payment_era_id"
    t.string   "cas_group_code",         :limit => 2
    t.string   "cas_hipaa_code",         :limit => 5
    t.decimal  "adjustment_amount",                   :precision => 18, :scale => 2
    t.integer  "adjustment_quantity",    :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_level_adjustments_eras", ["service_payment_era_id"], :name => "FK_service_adjustments_service_pay_era"

  create_table "service_payment_eobs", :force => true do |t|
    t.integer  "insurance_payment_eob_id"
    t.string   "service_procedure_code",                           :limit => 5
    t.string   "service_modifier1",                                :limit => 2
    t.string   "service_modifier2",                                :limit => 2
    t.string   "service_modifier3",                                :limit => 2
    t.string   "service_modifier4",                                :limit => 2
    t.decimal  "service_procedure_charge_amount",                                :precision => 10, :scale => 2
    t.decimal  "service_paid_amount",                                            :precision => 10, :scale => 2
    t.string   "service_quantity",                                 :limit => 20
    t.decimal  "primary_payment",                                                :precision => 10, :scale => 2
    t.decimal  "service_co_insurance",                                           :precision => 10, :scale => 2
    t.decimal  "service_deductible",                                             :precision => 10, :scale => 2
    t.decimal  "service_co_pay",                                                 :precision => 10, :scale => 2
    t.decimal  "service_no_covered",                                             :precision => 10, :scale => 2
    t.decimal  "service_discount",                                               :precision => 10, :scale => 2
    t.decimal  "service_balance",                                                :precision => 10, :scale => 2
    t.decimal  "service_allowable",                                              :precision => 10, :scale => 2
    t.string   "service_claim_adjustment_group_code",              :limit => 4
    t.string   "service_claim_adjustment_reason_code",             :limit => 5
    t.string   "service_claim_adjustment_reason_code_description", :limit => 50
    t.integer  "service_units_of_service_being_adjusted"
    t.date     "date_of_service_from"
    t.date     "date_of_service_to"
    t.string   "service_provider_control_number",                  :limit => 30
    t.string   "service_reference_identification_number",          :limit => 30
    t.string   "service_amount_qualifier_code",                    :limit => 30
    t.decimal  "service_amount",                                                 :precision => 10, :scale => 2
    t.string   "service_code_list_qualifier",                      :limit => 3
    t.string   "service_industry_code",                            :limit => 30
    t.string   "service_provider_number",                          :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
    t.string   "charges_code"
    t.string   "charges_groupcode"
    t.string   "noncovered_code"
    t.string   "noncovered_groupcode"
    t.string   "discount_code"
    t.string   "discount_groupcode"
    t.string   "coinsurance_code"
    t.string   "coinsurance_groupcode"
    t.string   "deductuble_code"
    t.string   "deductuble_groupcode"
    t.string   "copay_code"
    t.string   "copay_groupcode"
    t.string   "payment_code"
    t.string   "payment_groupcode"
    t.string   "primary_payment_code"
    t.string   "primary_payment_groupcode"
    t.string   "charges_code_description"
    t.string   "noncovered_code_description"
    t.string   "discount_code_description"
    t.string   "coinsurance_code_description"
    t.string   "deductuble_code_description"
    t.string   "copay_code_description"
    t.string   "payment_code_description"
    t.string   "primary_payment_code_description"
    t.decimal  "contractual_amount",                                             :precision => 10, :scale => 2
    t.string   "contractual_groupcode"
    t.string   "contractual_code"
    t.string   "contractual_code_description"
    t.string   "revenue_code"
    t.string   "procedure_code_type"
    t.string   "inpatient_code"
    t.string   "outpatient_code"
    t.decimal  "expected_payment",                                               :precision => 10, :scale => 2
    t.string   "rx_number"
    t.decimal  "denied",                                                         :precision => 10, :scale => 2
    t.string   "denied_code"
    t.string   "denied_groupcode"
    t.string   "denied_code_description"
    t.integer  "claim_service_information_id"
    t.string   "bundled_procedure_code",                           :limit => 5
    t.decimal  "drg_amount",                                                     :precision => 9,  :scale => 2
    t.decimal  "retention_fees",                                                 :precision => 10, :scale => 2
    t.string   "line_item_number",                                 :limit => 40
    t.decimal  "pbid",                                                           :precision => 10, :scale => 2
    t.string   "payment_status_code",                              :limit => 15
    t.integer  "copay_reason_code_id"
    t.integer  "coinsurance_reason_code_id"
    t.integer  "contractual_reason_code_id"
    t.integer  "deductible_reason_code_id"
    t.integer  "denied_reason_code_id"
    t.integer  "discount_reason_code_id"
    t.integer  "noncovered_reason_code_id"
    t.integer  "primary_payment_reason_code_id"
    t.decimal  "service_prepaid",                                                :precision => 10, :scale => 2
    t.string   "service_plan_coverage",                            :limit => 5
    t.integer  "prepaid_reason_code_id"
    t.decimal  "patient_responsibility",                                         :precision => 10, :scale => 2
    t.string   "service_cdt_qualifier"
    t.integer  "pr_reason_code_id"
  end

  add_index "service_payment_eobs", ["insurance_payment_eob_id"], :name => "service_payment_eobs_idfk_1"

  create_table "service_payment_eobs_ansi_remark_codes", :force => true do |t|
    t.integer  "service_payment_eob_id", :null => false
    t.integer  "ansi_remark_code_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_payment_eobs_ansi_remark_codes", ["service_payment_eob_id"], :name => "idx_spearc_service_payment_eob_id"

  create_table "service_payment_eobs_reason_codes", :force => true do |t|
    t.integer  "service_payment_eob_id"
    t.integer  "reason_code_id"
    t.string   "adjustment_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_payment_eras", :force => true do |t|
    t.integer  "insurance_payment_era_id",                                                        :null => false
    t.string   "service_product_qualifier",          :limit => 2,                                 :null => false
    t.string   "service_procedure_code",             :limit => 48
    t.string   "service_modifier1",                  :limit => 2
    t.string   "service_modifier2",                  :limit => 2
    t.string   "service_modifier3",                  :limit => 2
    t.string   "service_modifier4",                  :limit => 2
    t.decimal  "service_procedure_charge_amount",                  :precision => 18, :scale => 2
    t.decimal  "service_paid_amount",                              :precision => 18, :scale => 2
    t.string   "revenue_code",                       :limit => 48
    t.integer  "service_quantity",                   :limit => 8
    t.string   "original_service_product_qualifier", :limit => 2
    t.string   "original_service_procedure_code",    :limit => 48
    t.string   "original_service_modifier1",         :limit => 2
    t.string   "original_service_modifier2",         :limit => 2
    t.string   "original_service_modifier3",         :limit => 2
    t.string   "original_service_modifier4",         :limit => 2
    t.string   "original_procedure_description",     :limit => 80
    t.integer  "original_service_quantity",          :limit => 8
    t.date     "date_of_service_from"
    t.date     "date_of_service_to"
    t.string   "line_item_number",                   :limit => 50
    t.string   "service_policy_identification",      :limit => 50
    t.string   "service_identification_qualifier",   :limit => 3
    t.string   "service_identifier",                 :limit => 50
    t.string   "service_amount_qualifier_code",      :limit => 3
    t.decimal  "service_amount",                                   :precision => 18, :scale => 2
    t.decimal  "service_supp_quantity",                            :precision => 15, :scale => 2
    t.string   "service_supp_quantity_qualifier",    :limit => 3
    t.string   "service_remark_code_qualifier",      :limit => 3
    t.string   "service_remark_code",                :limit => 30
    t.decimal  "primary_payment",                                  :precision => 18, :scale => 2
    t.decimal  "service_co_insurance",                             :precision => 18, :scale => 2
    t.decimal  "service_deductible",                               :precision => 18, :scale => 2
    t.decimal  "service_co_pay",                                   :precision => 18, :scale => 2
    t.decimal  "service_no_covered",                               :precision => 18, :scale => 2
    t.decimal  "service_discount",                                 :precision => 18, :scale => 2
    t.decimal  "contractual_amount",                               :precision => 18, :scale => 2
    t.decimal  "denied",                                           :precision => 18, :scale => 2
    t.string   "noncovered_code",                    :limit => 5
    t.string   "noncovered_groupcode",               :limit => 2
    t.string   "discount_code",                      :limit => 5
    t.string   "discount_groupcode",                 :limit => 2
    t.string   "coinsurance_code",                   :limit => 5
    t.string   "coinsurance_groupcode",              :limit => 2
    t.string   "deductuble_code",                    :limit => 5
    t.string   "deductuble_groupcode",               :limit => 2
    t.string   "copay_code",                         :limit => 5
    t.string   "copay_groupcode",                    :limit => 2
    t.string   "primary_payment_code",               :limit => 5
    t.string   "primary_payment_groupcode",          :limit => 2
    t.string   "contractual_groupcode",              :limit => 5
    t.string   "contractual_code",                   :limit => 2
    t.string   "denied_code",                        :limit => 5
    t.string   "denied_groupcode",                   :limit => 2
    t.string   "era_misc_svc_segments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_payment_eras", ["insurance_payment_era_id"], :name => "FK_service_pay_eras_ins_pay_era"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "shifts", :force => true do |t|
    t.string "name"
    t.time   "start_time"
    t.float  "duration"
  end

  create_table "site_settings", :force => true do |t|
    t.boolean "show_userid", :default => true
    t.integer "per_page",    :default => 30
  end

  create_table "statuses", :force => true do |t|
    t.string "value"
  end

  create_table "tats", :force => true do |t|
    t.datetime "expected_time"
    t.string   "comments"
    t.integer  "batch_id"
  end

  add_index "tats", ["batch_id"], :name => "tats_idfk_1"

  create_table "throughput_report_breached_informations", :force => true do |t|
    t.string   "process_name",  :limit => 25
    t.datetime "breached_time"
    t.datetime "updated_at"
  end

  create_table "throughput_reports", :force => true do |t|
    t.string   "process_name",        :limit => 25
    t.integer  "queue_volume"
    t.integer  "processing_volume"
    t.integer  "completed_volume"
    t.string   "status",              :limit => 50
    t.decimal  "threshold_tolerance",                :precision => 10, :scale => 0
    t.decimal  "current_tolerance",                  :precision => 10, :scale => 0
    t.time     "threshold_duration"
    t.time     "current_duration"
    t.string   "partner_name",        :limit => 25
    t.string   "client_name",         :limit => 50
    t.integer  "client_id"
    t.string   "facility_name",       :limit => 100
    t.integer  "facility_id"
    t.string   "lockbox_name",        :limit => 50
    t.string   "batch_type",          :limit => 20
    t.boolean  "current"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "breached_time"
    t.datetime "arrival_date"
    t.integer  "order_number"
  end

  create_table "throughput_thresholds", :force => true do |t|
    t.string   "process_name",        :limit => 25
    t.decimal  "threshold_tolerance",               :precision => 10, :scale => 0
    t.time     "threshold_duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twice_keying_fields", :force => true do |t|
    t.string   "field_name"
    t.integer  "client_id"
    t.integer  "facility_id"
    t.integer  "reason_code_set_name_id"
    t.integer  "processor_id"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_activity_logs", :force => true do |t|
    t.integer  "user_id"
    t.string   "role",         :limit => 45
    t.string   "activity",     :limit => 45
    t.integer  "entity_id"
    t.string   "entity_name",  :limit => 45
    t.string   "description"
    t.datetime "performed_at"
  end

  add_index "user_activity_logs", ["user_id"], :name => "fk_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                                  :limit => 40
    t.string   "name",                                   :limit => 100, :default => ""
    t.string   "email",                                  :limit => 100
    t.string   "crypted_password",                       :limit => 40
    t.string   "salt",                                   :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",                         :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "image_permision"
    t.string   "image_grid_permision"
    t.string   "image_835_permision"
    t.string   "activity_log_permission",                               :default => "1"
    t.boolean  "allocation_status",                                     :default => false
    t.datetime "last_activity_at"
    t.string   "batch_status_permission"
    t.string   "file_837_report_permission"
    t.boolean  "is_deleted",                                            :default => false
    t.float    "eob_accuracy",                                          :default => 100.0
    t.float    "field_accuracy",                                        :default => 100.0
    t.integer  "shift_id"
    t.integer  "total_eobs",                                            :default => 0
    t.integer  "rejected_eobs",                                         :default => 0
    t.integer  "processing_rate_triad",                                 :default => 5
    t.integer  "processing_rate_others",                                :default => 8
    t.integer  "total_fields",                                          :default => 0
    t.integer  "total_incorrect_fields",                                :default => 0
    t.integer  "eob_qa_checked",                                        :default => 0
    t.string   "session"
    t.string   "rating"
    t.integer  "teamleader_id"
    t.boolean  "login_status",                                          :default => false
    t.string   "employee_id",                            :limit => 40
    t.boolean  "eligible_for_payer_wise_job_allocation"
    t.datetime "last_job_completed_at"
    t.string   "location",                               :limit => 50
    t.boolean  "auto_allocation_enabled",                               :default => true
    t.string   "num_cre_errors"
    t.boolean  "fc_edit_permission",                                    :default => false
    t.boolean  "grant_fc_edit_permission",                              :default => false
  end

  add_index "users", ["eligible_for_payer_wise_job_allocation"], :name => "index_users_on_eligible_for_payer_wise_job_allocation"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["login_status", "allocation_status"], :name => "by_login_status_and_allocation_status"
  add_index "users", ["shift_id"], :name => "fk_users_shift_id"

  create_table "web_service_logs", :force => true do |t|
    t.string   "service",       :null => false
    t.string   "query",         :null => false
    t.integer  "response_code", :null => false
    t.integer  "response_time", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
