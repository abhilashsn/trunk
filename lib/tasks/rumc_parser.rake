namespace :rumc_parser do
  desc "To update the parser type of Richmond University Medical Center to Wachovia"
  task :update_rumc_parser_type => :environment do
    sql = "UPDATE facilities SET index_file_parser_type='Wachovia' WHERE name='Richmond University Medical Center'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute(sql)
  end
end
   