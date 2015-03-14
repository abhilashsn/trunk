class Unified835Output::OptimHealthcareWfGenerator < Unified835Output::Generator

   # Start of N1_PE Segment Details #
  def identification_code_qualifier(*options)
    identification_code_qualifier_for_optim(*options)
  end

  def identification_code(*options)
    identification_code_for_optim(*options)
   end
  # End of N1_PE Segment Details #

  
end
