class MpiSearchesController < ApplicationController
  layout "basic"

  require_role ["supervisor", "admin", "processor", "qa"]

  def index
    if params[:mpi_search]
      @mpi_search = Hashie::Mash.new(params[:mpi_search])
    else
            @mpi_search = Hashie::Mash.new(params)
    end
    @mpi_search[:page] = params[:page]
    search_method = Settings.claim_lookup_service
    service_name = "#{search_method.capitalize}ClaimLookup"
    service_object = Kernel.const_get(service_name)
    @claim_search_result = service_object.search(@mpi_search)
    @mpi_results = @claim_search_result.mpi_results
  end
end
