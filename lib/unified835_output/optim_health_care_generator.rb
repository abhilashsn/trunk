class Unified835Output::OptimHealthCareGenerator < Unified835Output::QuadaxGenerator

  # Start of N1_PE Segment Details #
  def identification_code_qualifier(*options)
    identification_code_qualifier_for_optim(*options)
  end

  def identification_code(*options)
    identification_code_for_optim(*options)
   end
  # End of N1_PE Segment Details #

  # Start of REF_TJ Segment Details
  def tax_payer_identification_number(*options)
    nil_segment
  end
  # End of REF_TJ Segment Details
    
end
