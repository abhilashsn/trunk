namespace :rumc_index_format do
  desc "To update the index file format of Richmond University Medical Center"
  task :update_rumc_index_file => :environment do
    sql = "UPDATE facilities SET index_file_format='DAT' WHERE name='Richmond University Medical Center'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute(sql)
  end
end