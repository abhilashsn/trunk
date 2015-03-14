class HipaaCodesController < ApplicationController
  # GET /hipaa_codes
  # GET /hipaa_codes.xml
  layout 'standard'
  require_role ["admin","supervisor"]
  def index
    @hipaa_codes = HipaaCode.scoped.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @hipaa_codes }
    end
  end

  # GET /hipaa_codes/1
  # GET /hipaa_codes/1.xml
  def show
    @hipaa_code = HipaaCode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hipaa_code }
    end
  end

  # GET /hipaa_codes/new
  # GET /hipaa_codes/new.xml
  def new
    @hipaa_code = HipaaCode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @hipaa_code }
    end
  end

  # GET /hipaa_codes/1/edit
  def edit
    @hipaa_code = HipaaCode.find(params[:id])
    @id = params[:id]
  end

  # POST /hipaa_codes
  # POST /hipaa_codes.xml
  def create
    @hipaa_code = HipaaCode.new
    @hipaa_code.hipaa_adjustment_code = params[:hipaa_code][:hipaa_adjustment_code]
    @hipaa_code.hipaa_code_description = params[:hipaa_code][:hipaa_code_description]
    if @hipaa_code.save
      @hipaa_code.add_to_hipaa_codes_global_variable
      flash[:notice] = 'HipaaCode was successfully created.'
    else
      flash[:notice] = 'HipaaCode was not created.'
    end
    redirect_to :action => 'index'
    
  end

  # PUT /hipaa_codes/1
  # PUT /hipaa_codes/1.xml
  def update
    @hipaa_code = HipaaCode.find(params[:id])
    @hipaa_code.hipaa_adjustment_code = params[:hipaa_code][:hipaa_adjustment_code]
    @hipaa_code.hipaa_code_description = params[:hipaa_code][:hipaa_code_description]
  
    if @hipaa_code.save
       @hipaa_code.add_to_hipaa_codes_global_variable
      flash[:notice] = 'HipaaCode was successfully updated.'
      redirect_to :action => 'index'
    else
      format.html { render :action => "edit" }
      format.xml  { render :xml => @hipaa_code.errors, :status => :unprocessable_entity }
    end
  
  end

  # DELETE /hipaa_codes/1
  # DELETE /hipaa_codes/1.xml
  def destroy_code
    hipaa_code = HipaaCode.find(params[:id])
    if hipaa_code.qualified_for_deletion?
      hipaa_code.delete_from_hipaa_codes_global_variable
      if hipaa_code.destroy
        flash[:notice] = "Hipaa Code : #{hipaa_code.hipaa_adjustment_code} has been deleted successfully"
      end
    else
      flash[:notice] = "Hipaa Code : #{hipaa_code.hipaa_adjustment_code} has a reason code associated to it, so cannot delete it"
    end
    redirect_to :action => :index  
  end

end
