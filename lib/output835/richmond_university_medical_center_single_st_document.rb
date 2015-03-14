class Output835::RichmondUniversityMedicalCenterSingleStDocument < Output835::SingleStDocument

  def transactions
    segments = []
    check_nums = checks.collect{|check| check.check_number}
    check_klass = Output835.class_for("SingleStCheck", facility)
    Output835.log.info "Applying class #{check_klass}"
    check = check_klass.new(checks, facility, nil, @element_seperator, check_nums)
    check.instance_variable_set("@plb_excel_sheet", @plb_excel_sheet)
    segments += check.generate
    segments
  end
 
end
