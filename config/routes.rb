Revremit::Application.routes.draw do

  devise_for :users, :path_names => {:sign_in => '/login', :sign_out => '/logout'}, :controllers => {:registrations => "users"} do
    get "/login" => "devise/sessions#new", :as => :new_user_session
    post "/login" => "devise/sessions#create", :as => :user_session
  end

  devise_scope :user do
    root :to => "devise/sessions#new", :path => "/"
    get "/sessions/new", :to => "devise/sessions#new"
    get "/login", :to => "devise/sessions#new"
    get "/logout", :to => "sessions#destroy"
    get "/users/logout", :to => "devise/sessions#destroy"
  end

  resources :mpi_statistics_reports

  resources :web_service_logs

  match '/sessions/new',                  :to => 'devise/sessions#new'
  match '/welcome',                       :to => 'sessions#create'
  match '/logout',                        :to => 'sessions#destroy'
  match '/users/logout',                  :to => 'devise/sessions#destroy'
  match '/keep_alive',                    :to => 'sessions#keep_alive'
  match '/get_user_logged_in',            :to => 'sessions#get_user_logged_in'
  match '/version',                       :to => 'sessions#version', :as => "version"
  match '/disclaimer',                    :to => 'sessions#disclaimer', :as => "disclaimer"
  
  match 'batch/unprocessed_batches',      :to => 'hlsc#unprocessed_batches'
  match 'batch/batch_status',             :to => 'hlsc#batch_status'
  
  match 'datacaptures/payer_informations', :to => 'datacaptures#payer_informations'
  match 'datacaptures/micrwise_payer_informations', :to => 'datacaptures#micrwise_payer_informations'

  match 'testgenerate',                     :to => 'test#generate'

  match 'report/listing_my_jobs',                     :to => 'report#listing_my_jobs'
  match 'report/completed_eobs_report',                     :to => 'report#completed_eobs_report'

  #match 'paper/new',   :to => 'papers#new', :method => :get
  #match 'paper/create',   :to => 'papers#create', :method => :post
  match '/unzipped_files/:first/:second/:filename', :to => 'image#show', :method => :get, :constraints => {:filename => /.*/}
  

  resources :mpi_searches

  resources :file837_informations do
    post :list, :on => :collection
    get :list, :on => :collection
    post :search, :on => :collection
    get :search, :on => :collection
    post :update, :on => :collection
    get :update, :on => :collection
    post :claim_retrieval, :on => :collection
    get :claim_retrieval, :on => :collection
    post :svc_popup, :on => :collection
    get :svc_popup, :on => :collection
    get :delete_confirmed, :on => :collection
  end
  
  resources :roles, :client_reported_errors
  
  namespace :admin do   
    resources :batch do
      post :batches_completed,        :on => :collection
      get :export_batches,            :on => :collection
      post :status_wise_batch_list,   :on => :collection
      post :status_change,            :on => :collection
      get :reasoncode_csv,            :on => :collection
      get :batch_load,                :on => :collection
      get :allocate,                  :on => :collection
      post :allocate,                 :on => :collection
      post :batchlist,                :on => :collection
      get :batchlist,                 :on => :collection
      get :archive_batch,             :on => :collection
      get :batch_payer_report_835,    :on => :collection
      post :batch_payer_report_835,   :on => :collection
      get :batches_completed,         :on => :collection
      get :status_wise_batch_list,    :on => :collection
      post :delete_batches,           :on => :collection
      post :delete_jobs,              :on => :collection      
      post :batch_archive,            :on => :collection
      get :batches_without_tat_comment, :on => :collection
      post :batches_without_tat_comment, :on => :collection
      post :auto_complete_for_batch_tat_comment, :on => :collection
      get :work_list,                  :on => :collection
      post :work_list,                 :on => :collection
      post :update_allocation_type_and_batch_status, :on => :collection
      post :get_batchids_belong_to_different_allocation_queue, :on => :collection
      post :get_invalid_batchids_for_changing_status_to_output_ready, :on => :collection
      get :export_work_list,                  :on => :collection
    end
    
    resources :import837 do
      get :index, :on => :collection
      post :index, :on => :collection
      get :upload837, :on => :collection
      post :upload837, :on => :collection
    end
    
    resources :ach_exception do
      get :index, :on => :collection
      post :index, :on => :collection
      get :approval, :on => :collection
      post :approval, :on => :collection
    end
    
    resources :era_exception do
      get :index, :on => :collection
      post :index, :on => :collection
      get :approval, :on => :collection
      post :approval, :on => :collection
      get :site_search, :on => :collection
      post :site_search, :on => :collection
      get :payer_search, :on => :collection
      post :payer_search, :on => :collection
    end

    resources :upload do
      get :upload,  :on => :collection
    end
    
    resources :payer do
      get :list,                      :on => :collection
      get :list_new_payers,           :on => :collection
      post :list_new_payers,          :on => :collection
      get :manage_newly_added_codes,  :on => :collection
      post :manage_newly_added_codes,  :on => :collection
      get :new_payers,                :on => :collection
      post :get_facility,             :on => :collection
      get :get_facility_for_client,   :on => :collection
      get :export_to_csv,             :on => :collection
      get :list_approved_payers,   :on => :collection
      post :list_approved_payers,  :on => :collection
      get :payer_name_search,         :on => :collection
      post :approve_patient_payers,   :on => :collection
      post :export_to_csv,   :on => :collection
      post :get_facility_for_output_payid_and_onbase_name,   :on => :collection
      post :get_facility_for_payment_and_allowance_code,   :on => :collection
    end
    
    resources :pop_up do
      post :delete_documents,         :on => :collection
      get :show,                      :on => :collection
      get :add_message,               :on => :collection
      get :select_payer,              :on => :collection
      post :select_payer,             :on => :collection
      post :submit,                   :on => :collection
      post :create_alerts,            :on => :collection
      post :delete_messages,          :on => :collection
      post :get_facilities_by_client, :on => :collection
      get  :upload_document,          :on => :collection
      post :save_upload_document,     :on => :collection
      get :alert_list,                :on => :collection
    end

    resources :twice_keying_fields do
      post :create,                       :on => :collection
      post :get_facilities_by_client,     :on => :collection
      get  :list,                         :on => :collection
      post :delete,                       :on => :collection
      post :get_field_names,              :on => :collection
    end
    
    resources :job do
      get :processor_allocated_jobs,  :on => :collection
      post :deallocate_auto_allocate_jobs,  :on => :collection
      post :allocate_deallocate,  :on => :collection
      collection do
        get :allocate_payer_jobs
        get :add_processor
        get :assign
        post :assign
        get :allocate
        post :allocate
        post :set_payer_group_in_job_allocation_view
        get :deallocate_processor
        get :add_qa
        get :deallocate_qa
        get :create_new_job
        get :list_images
        post :delete_jobs
        get :delete_jobs
        post :reorder_images
        get :create_jobs
        get :aggregate_835_report
        get :manual_split_job
        post :create_sub_jobs
        get :auto_split_job
        get :incomplete
        post :incomplete
        post :update_incomplete_jobs
        get :unattended_jobs
        post :unattended_jobs
        get :change_jobs_to_excluded
        get :change_jobs_to_non_excluded
        get :additional_job_request_queue
        post :remove_jobs_from_additional_job_request_queue
        post :set_is_correspondence
      end
    end

    resources :temp_jobs

    resources :eob_error do
      collection do
        get :list
      end
    end
    resources :facility do
      post :save_facility_cut_configurations, :on => :collection
      post :delete_facility_cut_configurations, :on => :collection
      post :auto_complete_for_output_insu_predefined_payer, :on => :collection
      post :auto_complete_for_output_pat_pay_predefined_payer, :on => :collection
      post :delete_facilities, :on => :collection
      get  :get_faiclity_ids, :on => :collection
      post :get_faiclity_ids, :on => :collection      
    end 
    
    resources :user do
      post :delete_users,             :on => :collection
      get :list_processor_occupancy,  :on => :collection
      get :processor_report,          :on => :collection
      post :processor_report,         :on => :collection
      post :create_or_update_clients_to_users, :on => :collection
      get :create_or_update_clients_to_users, :on => :collection
      post :create_or_update_facilities_to_users, :on => :collection
      get :create_or_update_facilities_to_users, :on => :collection
      post :idle_processors, :on => :collection
      get :idle_processors, :on => :collection
      get :associate_facilities_to_users, :on => :collection
      post :associate_facilities_to_users, :on => :collection
      get :change_password, :on => :collection
      post :update_password, :on => :collection
    end

    resources :client do
      get :list,  :on => :collection
      post :list,  :on => :collection
      get :new ,:on => :collection
      post :new, :on => :collection
      post :update_or_delete_clients, :on => :collection
      get :check_presence_of_facility, :on => :collection
      get :check_presence_of_alert, :on => :collection
      get :add ,:on => :collection
      post :add, :on => :collection    
    end
    
    get "download_output/index"
    post "download_output/index"
    get "download_client_level_output/index"
    post "download_client_level_output/index"
    get "batch_upload/upload_zipfile"
    post "batch_upload/uploadFile"
    get "batch_upload/get_inbound_records"
    post "config_settings/upload"
    post "config_settings/download"
    get "config_settings/partners_list"
    #get "import_837/index"
    #post "import_837/index"

  end
  
  resources :insurance_payment_eobs do
    collection do
      get :show_eob_grid
      get :show_orbograph_correspondance_grid
      get :mpi_search
      get :is_npi_tin_valid_for_facility
      get :get_upmc_tin
      get :claim
      get :claimqa
      get :capitation_account_save
      get :loading_patient_details_in_eob_grid
      get :auto_complete_for_payer_popup
      get :auto_complete_for_payer_address_one
      get :auto_complete_for_payee_name
      get :auto_complete_for_insurancepaymenteob_place_of_service
      get :auto_complete_for_payercode_adjustment_code
      get :auto_complete_for_payercode_adjustment_desc
      get :auto_complete_for_noncovered_adjustment_code
      get :auto_complete_for_denied_adjustment_code
      get :auto_complete_for_discount_adjustment_code
      get :auto_complete_for_contractual_adjustment_code
      get :auto_complete_for_coinsurance_adjustment_code
      get :auto_complete_for_deductuble_adjustment_code
      get :auto_complete_for_copay_adjustment_code
      get :auto_complete_for_payment_adjustment_code
      get :auto_complete_for_primary_adjustment_code
      get :auto_complete_for_noncovered_desc_adjustment_desc
      get :auto_complete_for_denied_desc_adjustment_desc
      get :auto_complete_for_discount_desc_adjustment_desc
      get :auto_complete_for_coinsurance_desc_adjustment_desc
      get :auto_complete_for_deductuble_desc_adjustment_desc
      get :auto_complete_for_copay_desc_adjustment_desc
      get :auto_complete_for_primary_desc_adjustment_desc
      get :auto_complete_for_contractual_desc_adjustment_desc
      get :auto_complete_for_test_adjustment_code
      get :auto_complete_for_test_adjustment_desc
      get :auto_complete_for_provider_provider_last_name
      get :auto_complete_for_provider_provider_npi_number
      get :get_saved_transaction_type
      get :get_job_allocation_queue
      get :user_report
      get :calculate_total_claim_interest
      get :confirm_cpt_code
      get :check_presence_of_url
      post :check_presence_of_url
      get :any_eob_present
    end
  end

  match ':controller(/:action(/:id(.:format)))'

  # TODO: Need to set properly
  # match ':controller/service.wsdl'

  #match 'version', :to => 'sessions#version', :as => "version"
  #match 'signup', :to => 'dashboard#signup', :as => "signup"
  #match 'edit', :to => 'user#update', :as => "edit"
  #match 'update_rejection_comments_for_client', :to => 'admin/facility#update_rejection_comments_for_client'
  
  #match '/unzipped_files/:first/:second/:filename', :to => 'image#show', :requirements => {:filename => /.*/}  
  
                
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
