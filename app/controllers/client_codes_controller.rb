class ClientCodesController < ApplicationController
  # GET /client_codes
  # GET /client_codes.xml
    layout 'standard'
    require_role ["admin","supervisor"]

  def index
    @client_codes = ClientCode.scoped.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @client_codes }
    end
  end

  # GET /client_codes/1
  # GET /client_codes/1.xml
  def show
    @client_code = ClientCode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @client_code }
    end
  end

  # GET /client_codes/new
  # GET /client_codes/new.xml
  def new
    @client_code = ClientCode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @client_code }
    end
  end

  # GET /client_codes/1/edit
  def edit
    @client_code = ClientCode.find(params[:id])
    @selected = @client_code.group_code
    @id = params[:id]
  end

  # POST /client_codes
  # POST /client_codes.xml
  def create
    @client_code = ClientCode.new
    @client_code.group_code = params[:group_code]
    @client_code.adjustment_code = params[:client_code][:adjustment_code]
    @client_code.adjustment_code_description = params[:client_code][:adjustment_code_description]
    
    if @client_code.save
      flash[:notice] = 'ClientCode was successfully created.'
      redirect_to :action => 'index'
    else
      flash[:notice] = 'ClientCode was not created.'
      redirect_to :action => 'index'
    end
  end

  # PUT /client_codes/1
  # PUT /client_codes/1.xml
  def update
    @client_code = ClientCode.find(params[:id])
    @client_code.group_code = params[:group_code]
    @client_code.adjustment_code = params[:client_code][:adjustment_code]
    @client_code.adjustment_code_description = params[:client_code][:adjustment_code_description]   
    if @client_code.save
      flash[:notice] = 'ClientCode was successfully updated.'
      redirect_to :action => 'index'
    else
      @selected = @client_code.group_code
      @id = params[:id]
      render :action => 'edit'
    end
  end

  # DELETE /client_codes/1
  # DELETE /client_codes/1.xml
  def destroy_code
    client_code = ClientCode.find(params[:id])
    if client_code.qualified_for_deletion?
      if client_code.destroy
        flash[:notice] = "Client Code : #{client_code.adjustment_code} has been deleted successfully"
      end
    else
      flash[:notice] = "Client Code : #{client_code.adjustment_code} has a reason code associated to it, so cannot delete it"
    end
    redirect_to :action => 'index'
  end
end
