namespace :horizon_eye_index_format do
  desc "To update the index file format of Horizon Eye"
  task :update_horizon_eye_index_file => :environment do
    sql = "UPDATE facilities SET index_file_format='DAT' WHERE name='HORIZON EYE'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute(sql)
  end
end