require 'spec_helper'
require 'devise/test_helpers' 


describe Admin::BatchController do
  
  before(:each) do
    
    sign_in FactoryGirl.create(:an_admin)
    @batch = FactoryGirl.create(:output_ready)
    @facility = @batch.facility
    @batch_id = @batch.id
  end
  
  it "should not archive the batches if none provided" do
    get :batch_archive, {:batch_to_delete => {"anjana" => 0}}
    expect(response).to redirect_to(batch_payer_report_835_admin_batch_index_path)
  end
  
  it "should archive the batches if provided" do
    get :batch_archive, {:batch_to_delete => {@batch_id.to_s => "1"}, :option1 => "Archive"}
    expect(response).to redirect_to(batch_payer_report_835_admin_batch_index_path)
  end
  
  it "should generate output if provided" do
    get :batch_archive, {:batch_to_delete => {@batch_id.to_s => "1"}, :option1 => "Generate Output"}
    expect(response).to redirect_to("/admin/batch/generate_output_files/#{@batch.id}?ids%5B%5D=#{@batch.id}") 
  end
  
  it "should generate_aggregate_operation_log if provided" do
    get :batch_archive, {:batch_to_delete => {@batch_id.to_s => "1"}, :option1 => "Generate Aggregate Ops Log"}
    expect(response).to redirect_to("/admin/batch/generate_aggregate_operation_log/#{@batch.id}?ids%5B%5D=#{@batch.id}") 
  end
  
  it "should generate images if provided" do
    get :batch_archive, {:batch_to_delete => {@batch_id.to_s => "1"}, :option1 => "Generate Images"}
    expect(response).to redirect_to(batch_payer_report_835_admin_batch_index_path)
  end
  
    
  it "should redirect after updation of tat comments with rdirect window unprocessed_batches" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment"}, :edited_field => "tat_comment", :redirect_window => "unprocessed_batches"}
    expect(response).to redirect_to(batch_unprocessed_batches_path)
  end
  
  it "should redirect after updation of tat comments with rdirect window batches without tat comment" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment"}, :edited_field => "tat_comment", :redirect_window => "batches_without_tat_comment"}
    expect(response).to redirect_to(batches_without_tat_comment_admin_batch_index_path)
  end
  
  it "should redirect after updation of tat comments with rdirect window allocate" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for allocate"}, :edited_field => "tat_comment", :redirect_window => "allocate"}
    expect(response).to redirect_to(allocate_admin_batch_index_path)
  end
  
  it "should redirect after updation of tat comments with rdirect window status_wise_batch_list" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for status_wise_batch_list"}, :edited_field => "tat_comment", :redirect_window => "status_wise_batch_list"}
    expect(response).to redirect_to(status_wise_batch_list_admin_batch_index_path)
  end
  
  it "should redirect after updation of tat comments with rdirect window batches_completed" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for batches_completed"}, :edited_field => "tat_comment", :redirect_window => "batches_completed"}
    expect(response).to redirect_to(batches_completed_admin_batch_index_path)
  end
  
  it "should redirect after updation of tat comments with rdirect window unprocessed_batches" do
    get :update_tat_comments, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment"}, :edited_field => "tat_comment", :redirect_window => "unprocessed_batches"}
    expect(response).to redirect_to(batch_unprocessed_batches_path)
  end
  
  it "should redirect after destroying of tat comments with rdirect window allocate" do
    get :delete_batch_tat_comment, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for allocate"}, :edited_field => "tat_comment", :redirect_window => "allocate"}
    expect(response).to redirect_to(allocate_admin_batch_index_path)
  end
  
  it "should redirect after destroying of tat comments with rdirect window status_wise_batch_list" do
    get :delete_batch_tat_comment, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for status_wise_batch_list"}, :edited_field => "tat_comment", :redirect_window => "status_wise_batch_list"}
    expect(response).to redirect_to(status_wise_batch_list_admin_batch_index_path)
  end
  
  it "should redirect after destroying of tat comments with rdirect window batches_completed" do
    get :delete_batch_tat_comment, {:id => @batch_id.to_s, :batch => {:tat_comment => "a test tat comment for batches_completed"}, :edited_field => "tat_comment", :redirect_window => "batches_completed"}
    expect(response).to redirect_to(batches_completed_admin_batch_index_path)
  end
  
  it "should list status wise batches for current user partner" do
    pu = FactoryGirl.create(:a_partner_u)
    partner = pu.partner
    user =  FactoryGirl.create(:a_partner_user)
    pu.update_attributes(:user_id => user.id, :partner_id => @batch.client.partner_id)
    @batch.client.update_attributes(:partner_id => partner.id)
    
    @batch.facility.update_attributes(:client_id => @batch.client.id)
    
    sign_in user
    
    get :status_wise_batch_list
    expect(assigns(:batches).size > 0).to be true
  end
  
  it "should list status wise batches for current user client" do
    batch = FactoryGirl.create(:batch1)
    cu = FactoryGirl.create(:a_client_u)
    # client = cu.client
    user =  FactoryGirl.create(:a_client_user)
    cu.update_attributes(:user_id => user.id, :client_id => batch.client.id)
    batch.facility.update_attributes(:client_id => batch.client.id)
    
    sign_in user
    
    get :batches_completed
    expect(assigns(:batches).size > 0).to be true
  end
  
  it "should list status wise batches for current user facility" do
    batch = FactoryGirl.create(:batch2)
    fu = FactoryGirl.create(:a_facility_u)
    user =  FactoryGirl.create(:a_facility_user)
    fu.update_attributes(:user_id => user.id, :facility_id => batch.facility.id)
    batch.facility.update_attributes(:client_id => batch.client.id)
    
    sign_in user
    
    get :status_wise_batch_list
    expect(assigns(:batches).size > 0).to be true
  end

end