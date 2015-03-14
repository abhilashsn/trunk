class ClaimValidationExceptionsController < ApplicationController
  require_role ["admin", "TL"]
  layout 'standard'

  # GET /claim_validation_exceptions
  # GET /claim_validation_exceptions.json
  def index
    @search = ClaimValidationException.search(params[:q])
    # @claim_validation_exceptions = ClaimValidationException.order("id desc").paginate(:page => params[:page])
    @claim_validation_exceptions = @search.result.paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @claim_validation_exceptions }
    end
  end

  # GET /claim_validation_exceptions/1
  # GET /claim_validation_exceptions/1.json
  def show
    @claim_validation_exception = ClaimValidationException.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @claim_validation_exception }
    end
  end

  # GET /claim_validation_exceptions/new
  # GET /claim_validation_exceptions/new.json
  def new
    @claim_validation_exception = ClaimValidationException.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @claim_validation_exception }
    end
  end

  # GET /claim_validation_exceptions/1/edit
  def edit
    @claim_validation_exception = ClaimValidationException.find(params[:id])
  end

  # POST /claim_validation_exceptions
  # POST /claim_validation_exceptions.json
  def create
    @claim_validation_exception = ClaimValidationException.new(params[:claim_validation_exception])

    respond_to do |format|
      if @claim_validation_exception.save
        format.html { redirect_to @claim_validation_exception, notice: 'Claim validation exception was successfully created.' }
        format.json { render json: @claim_validation_exception, status: :created, location: @claim_validation_exception }
      else
        format.html { render action: "new" }
        format.json { render json: @claim_validation_exception.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /claim_validation_exceptions/1
  # PUT /claim_validation_exceptions/1.json
  def update
    @claim_validation_exception = ClaimValidationException.find(params[:id])

    respond_to do |format|
      if @claim_validation_exception.update_attributes(params[:claim_validation_exception])
        format.html { redirect_to @claim_validation_exception, notice: 'Claim validation exception was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @claim_validation_exception.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /claim_validation_exceptions/1
  # DELETE /claim_validation_exceptions/1.json
  def destroy
    @claim_validation_exception = ClaimValidationException.find(params[:id])
    @claim_validation_exception.destroy

    respond_to do |format|
      format.html { redirect_to claim_validation_exceptions_url }
      format.json { head :ok }
    end
  end
end
