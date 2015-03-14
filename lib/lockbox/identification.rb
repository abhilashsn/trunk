module Lockbox
  class Identification
    attr_reader :name, :log, :lockbox
    @@patterns = {
      "Bank of America And PNC Format 1" => 
      {
        "pattern" => /^(\d+)\.(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\.(zip|ZIP)$/i,
        "lockbox" => 1
      },
      "Bank of America And PNC Format 2" => 
      {
        "pattern" => /^SDF(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})_([a-zA-Z0-9]+)_(\d{2})_(\d+)_(\d+)\.(zip|ZIP)$/i,
        "lockbox" => 8
      },
      "WellsFargo" =>
      {
        "pattern" => /^WFOWHSLCK_([a-zA-Z0-9]+)_([a-zA-Z0-9]+)_(\d+)_(\d{4})(\d{2})(\d{2})_(\d+)\.(zip|ZIP)$/i,
        "lockbox" => 3
      },
      "Wachovia" =>
      {
        "pattern" =>  /^wl_trsm_(\d+)_(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})_(\d+)\.(zip|ZIP)$/i,
        "lockbox" => 1
      }      
    }

    def initialize name, log=false
      @name = name
      @log = log
    end
    
    
    def parse
      @lockbox = nil
      @logger = ""
      @@patterns.keys.each do |key|
        @logger << "Trying #{key} against #{@name}\n" if @logger
        @name =~ @@patterns[key]["pattern"]
        if $&
          @logger << "#{@name} Matched for #{key} " if @logger
          @lockbox = eval("$#{@@patterns[key]["lockbox"]}")
          break
        else
          @logger << "#{@name} Not Matched for #{key} " if @logger
        end
      end
    end


    def log
     @logger
    end

    def findFacility
      facility = nil
      if @lockbox
        facility = FacilityLockboxMapping.find_by_lockbox_number(@lockbox).facility rescue nil
      end
      return facility
    end
    
  end
end
