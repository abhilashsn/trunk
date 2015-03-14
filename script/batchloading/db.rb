Environment = 'production' 
@db = nil
def make_connection
  database_yml = File.dirname(__FILE__) + "/../../config/database.yml"
  db_config =  YAML.load(File.open(database_yml))[Environment]
  
  #@db = Mysql.connect(db_config['host'], db_config['username'], db_config['password'], db_config['database'], db_config['port'])

  @db =  Mysql2::Client.new(:host => db_config['host'], 
  							:username => db_config['username'], 
  							:password => db_config['password'], 
  							:database => db_config['database'], 
  							:port => db_config['port'])

end

def querydb sql
  @db.query sql
end

