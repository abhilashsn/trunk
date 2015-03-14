module MpiStatisticsReportsHelper
  include Rack::Utils
  def sort_claim_header(text, field)
    parameters = parse_nested_query(request.query_string)

    key = field
    puts "parameters =  #{parameters}"
    unless params[:sort].blank?
      params[:sort] = (params[:sort].class == String ? params[:sort] : params[:sort].keys[0])
      key += "_reverse"  if params[:sort] == field
    end
    link_to "#{text}" , {:action => 'index', :mpi_apply => get_value_from_hash(parameters, 'mpi_apply'),
      :page_no => get_value_from_hash(parameters, 'page_no'), :patient_no => get_value_from_hash(parameters, 'patient_no'),
      :role => get_value_from_hash(parameters, 'role'), :job_id => get_value_from_hash(parameters, 'job_id'),
      :mpi_search_type => get_value_from_hash(parameters, 'mpi_search_type'),:page => @mpi_search[:page],
      :mode => get_value_from_hash(parameters, 'mode'),  :proc_start_time => get_value_from_hash(parameters, 'proc_start_time'),
      :facility_id => get_value_from_hash(parameters, 'facility_id'), :client_id => get_value_from_hash(parameters, 'client_id'),
      :sort => key , :patient_lname => get_value_from_hash(parameters, 'patient_lname'),
      :patient_fname => get_value_from_hash(parameters, 'patient_fname'), :total_charges => get_value_from_hash(parameters, 'total_charges'),
      :date_of_service_from =>  get_value_from_hash(parameters, 'date_of_service_from'), :insured_id => get_value_from_hash(parameters, 'insured_id'),
      :exact_serach => get_value_from_hash(parameters, 'exact_serach'), :payer_name => get_value_from_hash(parameters, 'payer_name'),:cpt_code => get_value_from_hash(parameters, 'cpt_code'),
      :claimleveleob => get_value_from_hash(parameters, 'claimleveleob'),:mpi_serach_facility_group => get_value_from_hash(parameters, 'mpi_serach_facility_group') 
    }
  end

  def get_value_from_hash(parameters, key)
    if(parameters.has_key?("#{key}"))    
      value = parameters["#{key}"]     
    else
      if parameters.has_key?('mpi_search')         
        if parameters["mpi_search"].has_key?("#{key}")
          value = parameters["mpi_search"]["#{key}"]
        end
      end
    end
    value
  end 
end