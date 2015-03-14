class Output835::RichmondUniversityMedicalCenterDocument < Output835::MedassetsDocument

  # passing check number array also to verify for patpay 
  # whether the check number is repeating
    
  def transactions
    segments = []
    check_nums = checks.collect{|check| check.check_number}
    checks.each_with_index do |check, index|
      Output835.log.info "Generating Check related segments for check: #{check.check_number}"
      check_klass = Output835.class_for("Check", facility)
      Output835.log.info "Applying class #{check_klass}" if index == 0
      check = check_klass.new(check, facility, index, @element_seperator, check_nums)
      segments += check.generate
    end
    segments
  end
  
end