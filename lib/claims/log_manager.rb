require 'fileutils'
require 'logger'

LOG_PATH = "#{Rails.root}/log/claims"

class LogManager

 #Claim Level Exception
 def self.log_claim_exception(msg)
   log = RevRemitLogger.new_logger(LogLocation::CLMLOG)
   info = "\n"
   msg.each do |key,value|
       info << "#{key}  : #{value} \n"              
   end
   log.info(info)
 end
 
 #ROR Exception
 def self.log_ror_exception(err,msg)
   log = RevRemitLogger.new_logger(LogLocation::CLMLOG)
   log.fatal("Caught exception; exiting")
   log.fatal(err)
   log.info(msg)
 end
  
end
