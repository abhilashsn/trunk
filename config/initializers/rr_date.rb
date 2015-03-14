class Date  
  class << self

    def rr_parse str, opt=false
       format = nil;
      if str =~ /^\d{1,2}\/\d{1,2}\/\d{4}$/ || str =~ /^\d{1,2}\/\d{1,2}\/\d{4} \d{2}:\d{2}:\d{2}$/
        format = "%m/%d/%Y"
      elsif str =~ /^\d{1,2}\/\d{1,2}\/\d{2}$/ || str =~ /^\d{1,2}\/\d{1,2}\/\d{2} \d{2}:\d{2}:\d{2}$/
        format = "%m/%d/%y"
      else
        format = nil
      end
      if format   
        return Date.strptime str, format 
      else
        return Date.parse(str, opt)
      end    
    end
    
  end  
end
