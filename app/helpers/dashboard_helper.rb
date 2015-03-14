module DashboardHelper
def client_activity_login(client_activity)
     @eob_type=nil
     #session[:client_id]=2
      @client_activity_log=ClientActivityLog.new()
    @client_activity_log.start_time=Time.now()
    @client_activity_log.user_id= session[:client_id]
#    
#    @client_activity_log.parent_id=session[:client_id]
    @client_activity_log.activity=client_activity
    @client_activity_log.job_id=0
    @client_activity_log.save
    session[:client_recored_id]= @client_activity_log.id
    @client_activity_log.update_attribute("job_id",@client_activity_log.id)
  end  
 

end
