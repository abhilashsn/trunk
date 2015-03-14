class ClientReportedErrorsController < ApplicationController
  # GET /client_reported_errors
  # GET /client_reported_errors.xml
  layout 'standard'
  def index
    @client_reported_errors = ClientReportedError.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @client_reported_errors }
    end
  end

  # GET /client_reported_errors/1
  # GET /client_reported_errors/1.xml
  def show
    @client_reported_error = ClientReportedError.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @client_reported_error }
    end
  end

  # GET /client_reported_errors/new
  # GET /client_reported_errors/new.xml
  def new
    @client_reported_error = ClientReportedError.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @client_reported_error }
    end
  end

  # GET /client_reported_errors/1/edit
  def edit
    @client_reported_error = ClientReportedError.find(params[:id])
  end

  # POST /client_reported_errors
  # POST /client_reported_errors.xml
  def create
    @client_reported_error = ClientReportedError.new(params[:client_reported_error])

    respond_to do |format|
      if @client_reported_error.save
        format.html { redirect_to(@client_reported_error, :notice => 'Client reported error was successfully created.') }
        format.xml  { render :xml => @client_reported_error, :status => :created, :location => @client_reported_error }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @client_reported_error.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /client_reported_errors/1
  # PUT /client_reported_errors/1.xml
  def update
    @client_reported_error = ClientReportedError.find(params[:id])

    respond_to do |format|
      if @client_reported_error.update_attributes(params[:client_reported_error])
        format.html { redirect_to(@client_reported_error, :notice => 'Client reported error was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @client_reported_error.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /client_reported_errors/1
  # DELETE /client_reported_errors/1.xml
  def destroy
    @client_reported_error = ClientReportedError.find(params[:id])
    @client_reported_error.destroy

    respond_to do |format|
      format.html { redirect_to(client_reported_errors_url) }
      format.xml  { head :ok }
    end
  end
end
