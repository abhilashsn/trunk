class ClaimSearchResult
  attr_accessor :mpi_results
  attr_accessor :response_code
  attr_accessor :response_message
  attr_accessor :response_time

  USER_MESSAGES = {
    400 => "Error - The search has omitted required parameters. Please check and resubmit.",
    401 => "System Error - Invalid provider ID!",
    403 => "System Error - Invalid credentials!",
    404 => "Error - No matching claims were found. Please modify the search parameters and resubmit.",
    406 => "Error - Multiple matching claims were found without a suitable match.",
    409 => "Error - Multiple matching claims were found. Please modify the search parameters and resubmit."
  }

  def initialize
    @mpi_results = []
    @response_code = nil
    @response_message = nil
    @response_time = nil
  end

  def user_message
    USER_MESSAGES[response_code] || "System Error - Unexpected Error (#{response_code}): #{response_message}"
  end
end
