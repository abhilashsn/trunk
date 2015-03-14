require 'spec_helper'
require 'devise/test_helpers' 


describe Admin::FacilityController do
  
  before(:each) do
    
    sign_in FactoryGirl.create(:an_admin)
    
    @oplogdetails = {"oplogtrue" => "1", "oplogfalse" => "0"}
    controller.stub(:set_values_for_details_column).with(anything).and_return({"params" => {:details=> {"1" => "2"}}})
    controller.stub(:set_facility_output_config_details_for_insurance).with(anything).and_return("params" => {:details_insu => {"1" => "2"}})
    controller.stub(:set_facility_output_config_details_for_patpay).with(anything)
    controller.stub(:check_edit_permissions)
    controller.stub(:default_code_adjustment_reason)
  end
  
    describe "Index Page" do
      it "should show list of facilities on this page" do
        get :index
        expect(assigns(:facilities).size > 0).to be true
        response.should render_template('index') 
      end
    end
    
    describe "Facility Creation" do
      it "should assign the default patient name if 'Other' specified on creation of new facility" do
        post :create, {:facility=>FactoryGirl.attributes_for(:facility), 
          :facil => {:def_pat_first_name => "Anjana", :def_pat_last_name => "Nair",:default_patient_name => "Other", :client => FactoryGirl.create(:client).id, :patient_payer => "0"},
             :facilities=>{"1"=>{"npi" => 11,"tin" => 222}},
              :detail =>{:default_cdt_qualifier => 1,:hide_incomplete_button_for_all => 1, :hide_incomplete_button_for_non_zero_payment => 2,:hide_incomplete_button_for_correspondance => 4, :npi_or_tin_validation => 4, :claim_normalized_factor => 6,:service_line_normalised_factor => 7, :default_plan_type => 5,:configurable_835 => 9 },
              :details_str => [], :payer_classification => [], :default_payer => [],
              :output_ins => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :output_insu => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :supple => {"a/bC d" => "1", "efgh" => "0", "g hj" => 1},
              :op_log_details => @oplogdetails             
              }
        set_expectations_for_default_patient_data
        set_expectations_for_op_log_details
        set_expectations_for_supplemental_outputs
      end
    end
    
    describe "Facility Updation" do
      it "should assign the default patient name if 'Other' specified on editing of new facility" do
        controller.stub(:set_values_for_details_column).with(anything).and_return({"params" => :details})
        fac = FactoryGirl.create(:facility)
        post :update, {:id=>fac.id, :facility => fac.attributes,
          :facil => {:def_pat_first_name => "Anjana", :def_pat_last_name => "Nair",:default_patient_name => "Other", :client => FactoryGirl.create(:client).id, :patient_payer => "0"},
             :facilities=>{"1"=>{"npi" => 11,"tin" => 222}},
              :detail =>{:default_cdt_qualifier => 1,:hide_incomplete_button_for_all => 1, :hide_incomplete_button_for_non_zero_payment => 2,:hide_incomplete_button_for_correspondance => 4, :npi_or_tin_validation => 4, :claim_normalized_factor => 6,:service_line_normalised_factor => 7, :default_plan_type => 5,:configurable_835 => 9 },
              :details_str => {:practice_id => 2}, :payer_classification => [], :default_payer => [],
              :output_ins => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :output_insu => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :supple => {"abcd" => "efgh"},
              :op_log_details => @oplogdetails             
              }

        set_expectations_for_default_patient_data
        set_expectations_for_op_log_details
      end
    end
  
  
  describe "Validate facility on create" do
    it "should validate with blank batch_load_type and return flash error for it " do
      facb = FactoryGirl.build(:facility, batch_load_type: nil )
      facb.save(validate: false)
       post :create, {:facility=>facb.attributes, 
          :facil => {:def_pat_first_name => "Anjana", :def_pat_last_name => "Nair",:default_patient_name => "Other", :client => FactoryGirl.create(:client).id, :patient_payer => "0"},
             :facilities=>{"1"=>{"npi" => 11,"tin" => 222}},
              :detail =>{:default_cdt_qualifier => 1,:hide_incomplete_button_for_all => 1, :hide_incomplete_button_for_non_zero_payment => 2,:hide_incomplete_button_for_correspondance => 4, :npi_or_tin_validation => 4, :claim_normalized_factor => 6,:service_line_normalised_factor => 7, :default_plan_type => 5,:configurable_835 => 9 },
              :details_str => [], :payer_classification => [], :default_payer => [],
              :output_ins => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :output_insu => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :supple => {"abcd" => "efgh"},
              :op_log_details => {"dfgf" => "dfg"}             
              }
        expect(assigns(:flash_message)).to eq("Select atleast one type of batch to load in the Input Setup")
    end
    
    it "should validate with default_service_date having 'other' and return flash error for it " do
      facb = FactoryGirl.build(:facility, default_service_date: "Other" )
      facb.save(validate: false)
       post :create, {:facility=>facb.attributes, 
          :facil => {:def_pat_first_name => "Anjana", :def_pat_last_name => "Nair",:default_patient_name => "Other", :client => FactoryGirl.create(:client).id, :patient_payer => "0"},
             :facilities=>{"1"=>{"npi" => 11,"tin" => 222}},
              :detail =>{:default_cdt_qualifier => 1,:hide_incomplete_button_for_all => 1, :hide_incomplete_button_for_non_zero_payment => 2,:hide_incomplete_button_for_correspondance => 4, :npi_or_tin_validation => 4, :claim_normalized_factor => 6,:service_line_normalised_factor => 7, :default_plan_type => 5,:configurable_835 => 9 },
              :details_str => [], :payer_classification => [], :default_payer => [],
              :output_ins => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :output_insu => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :supple => {"abcd" => "efgh"},
              :op_log_details => {"dfgf" => "dfg"}             
              }
        expect(assigns(:flash_message)).to eq("Select a date from Calendar for Default Date of Service in Grid setup if you are selecting Other")
    end
    
    it "should validate with facil patient payer as '1' and return flash error for it " do
      facb = FactoryGirl.build(:facility )
      facb.save(validate: false )
       post :create, {:facility=>facb.attributes, 
              :output_pat_pa => {:predefined_check => "0"},
              :output_pat_pay => {:multi_transaction =>"1" },
              :facil => {:def_pat_first_name => "Anjana", :def_pat_last_name => "Nair",:default_patient_name => "Other", :client => FactoryGirl.create(:client).id, :patient_payer => "1"},
              :facilities=>{"1"=>{"npi" => 11,"tin" => 222}},
              :detail =>{:default_cdt_qualifier => 1,:hide_incomplete_button_for_all => 1, :hide_incomplete_button_for_non_zero_payment => 2,:hide_incomplete_button_for_correspondance => 4, :npi_or_tin_validation => 4, :claim_normalized_factor => 6,:service_line_normalised_factor => 7, :default_plan_type => 5,:configurable_835 => 9 },
              :details_str => [], :payer_classification => [], :default_payer => [],
              :output_ins => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :output_insu => {:payment_corres_patpay_in_one_file => 1,:payment_corres_in_one_patpay_in_separate_file => 2,:payment_patpay_in_one_corres_in_separate_file => 3},
              :supple => {"abcd" => "efgh"},
              :op_log_details => {"dfgf" => "dfg"}             
              }
        expect(assigns(:flash_message)).to eq("Please give a patient payer ID if you check checkbox")
    end 
  end   
    

    def set_expectations_for_default_patient_data
      expect(assigns(:def_pat_name_oth)).to be true
      expect(assigns(:visible_oth_def_pat_name)).to eq("style='visibility:visible;'")
      expect(assigns(:facility).default_patient_name).to eq("Nair,Anjana")
    end
    
    def set_expectations_for_op_log_details
      expect(assigns(:oplogtrue)).to be true
      expect(assigns(:oplogfalse)).to be false
    end
    
    def set_expectations_for_supplemental_outputs
      expect(assigns(:abc_d)).to be true
      expect(assigns(:g_hj)).to be true
    end
        
end