namespace :horizon_eye_parser do
  desc "To update the parser type of HORIZON EYE"
  task :update_horizon_eye_parser_type => :environment do
    sql = "UPDATE facilities SET index_file_parser_type='Wachovia' WHERE NAME='HORIZON EYE'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute(sql)
  end
end
   