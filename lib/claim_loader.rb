require 'claims/transform_clienta837.rb'
require 'claims/transformer'
require 'package/dapackage'


class ClaimLoader
  attr_accessor :inbound_info_id
  
  include Claims
  
  def initialize(inbound_info_id)
    self.inbound_info_id = inbound_info_id
  end
  
  
  def perform
    begin
      inbound_info = InboundFileInformation.find(inbound_info_id)
      inbound_info.update_claim_loading_estimates
      facility  = inbound_info.facility
      $CNF = YAML.load(File.read("#{Rails.root}/lib/claims/yml/#{facility.sitecode}.yml"))
      $CNF['file_location'] = inbound_info.file_path
      $CNF['facility_name'] = facility.name
      $CNF['client_name'] = facility.client.name
      claim_name = $CNF['claim_name']
      transf = Kernel.const_get(claim_name).new 
      transf.load_claims(inbound_info_id)
      perform_sphinx_index
      inbound_info.mark_completed_loading
    rescue Exception => e
      revremit_exception = RevremitException.create({:exception_type =>"ClaimLoading", :system_exception => e.message + "\n" + e.backtrace.join("\n")})
      inbound_info.mark_exception(revremit_exception)  if inbound_info
    end      
  end

  def perform_sphinx_index
    mpi_db_name = Rails.configuration.database_configuration["mpi_data"]["database"]    
    cnf = YAML::load(File.open("#{Rails.root}/config/sphinx.yml"))
    spx_srv_adr = cnf["production"]["address"]
    spx_srv_usr = cnf["sphinx_server"]["userid"]    
    system "ssh #{spx_srv_usr}@#{spx_srv_adr} indexer #{mpi_db_name}_core --rotate"
  end

  
end
