module LogLocation
  IDXLOG = ["idxlog.log"        , "idxlog"]         # log/Date/idxlog/idxlog.log
  RCCLOG = ["rcc.log"           , ""]               # log/Date/rcc.log
  CLMLOG = ["claims.log"        , "claims"]         # log/Date/claims/claims.log
  PYRLOG = ["payer.log"         , ""]               # log/Date/payer.log
  TSLOG  = ["throughput_summary.log"  , ""]               # log/Date/throughput_summary.log
  XOPLOG = ["output_xml.log"    , "output"]         # log/Date/output/output_xml.log
  OOPLOG = ["output_others.log" , "output"]         # log/Date/output/output_others.log
  BLDELOG = ["error.log"  , "batchloading", :TIMESTAMP]   # logs/Date/batchloading/batchloading.log
  BLDSLOG = ["status.log"  , "batchloading", :TIMESTAMP]   # logs/Date/batchloading/batchloading.log
  OP835LOG = ["835.log"  , "output835"]             # logs/Date/batchloading/batchloading.log
  ALLOCATIONLOG = ["job_allocation.log"  , ""]      # logs/Date/job_allocation.log
  OCRPARSERLOG = ["ocr_parser.log", "ocr_parsing"]
  DCGRIDLOG = ["dc_grid.log", "dc_grid"]            # logs/Date/dc_grid.log
  OPERATIONLOG = ["operationlog.log", "operationlog"]            # logs/Date/operationlog.log
  WEBSERVICELOG = ["web_service.log", "web_service_log"]            # logs/Date/rms_web_service.log
  CONFIGEDITLOG = ["config_835_edit.log","config835edit"]
end

class RevRemitLogger < Logger

  def format_message(severity, timestamp, progname, msg)
    "[%s:%s] %s\n" % [severity, timestamp.to_formatted_s(:db), msg]    
  end

  def RevRemitLogger.new_logger(ltype, sync = false)
    dname = "log/#{Date.today.to_s(:number)}/#{ltype[1]}"
    FileUtils.mkdir_p(dname) unless File.directory?(dname)
    if ltype[2].eql?(:TIMESTAMP)
      ext = File.extname(ltype[0])
      fname = "#{dname}/#{ltype[0].gsub(ext, Process.pid.to_s + Time.now.strftime("%s") +  ext  )}"
    else
      fname = "#{dname}/#{ltype[0]}"
    end


    logfile = fname.is_a?(String) ? File.open(fname, 'a') : fname
    logfile.sync = sync

    log = RevRemitLogger.new(logfile)
    log.level = $RR_REFERENCES['application']['logger_level']
    
    return log
    
  end

end

# l = RevRemitLogger.new_logger(LogLocation::BLDLOG)
# l.debug "Testing"
