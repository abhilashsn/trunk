namespace :sphinx do

  desc 'Reindex on the remote Sphinx server'
  task :reindex do
    mpi_db_name = Rails.configuration.database_configuration["mpi_data_#{Rails.env}"]["database"]
    
    cnf = YAML::load(File.open("#{Rails.root}/config/sphinx.yml"))
    spx_srv_adr = cnf["production"]["address"]
    spx_srv_usr = cnf["sphinx_server"]["userid"]
    
    system "ssh #{spx_srv_usr}@#{spx_srv_adr} indexer #{mpi_db_name}_core --rotate"
  end

end