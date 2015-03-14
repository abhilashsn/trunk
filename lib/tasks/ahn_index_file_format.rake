namespace :ahn_index_file_format do
  desc "To update the index file format of AHN"
  task :update_ahn_index_file_format => :environment do
    sql = "UPDATE facilities SET index_file_format='CSV' WHERE name='AHN'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute(sql)
  end
end