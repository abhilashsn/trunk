class WebServiceLogsController < ApplicationController
  require_role "admin"

  # GET /web_service_logs
  # GET /web_service_logs.json
  def index
    @web_service_logs = WebServiceLog.limit(20).order("id desc")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @web_service_logs }
    end
  end

  # GET /web_service_logs/1
  # GET /web_service_logs/1.json
  def show
    @web_service_log = WebServiceLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @web_service_log }
    end
  end

  # GET /web_service_logs/new
  # GET /web_service_logs/new.json
  def new
    @web_service_log = WebServiceLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @web_service_log }
    end
  end

  # GET /web_service_logs/1/edit
  def edit
    @web_service_log = WebServiceLog.find(params[:id])
  end

  # POST /web_service_logs
  # POST /web_service_logs.json
  def create
    @web_service_log = WebServiceLog.new(params[:web_service_log])

    respond_to do |format|
      if @web_service_log.save
        format.html { redirect_to @web_service_log, notice: 'Web service log was successfully created.' }
        format.json { render json: @web_service_log, status: :created, location: @web_service_log }
      else
        format.html { render action: "new" }
        format.json { render json: @web_service_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /web_service_logs/1
  # PUT /web_service_logs/1.json
  def update
    @web_service_log = WebServiceLog.find(params[:id])

    respond_to do |format|
      if @web_service_log.update_attributes(params[:web_service_log])
        format.html { redirect_to @web_service_log, notice: 'Web service log was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @web_service_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /web_service_logs/1
  # DELETE /web_service_logs/1.json
  def destroy
    @web_service_log = WebServiceLog.find(params[:id])
    @web_service_log.destroy

    respond_to do |format|
      format.html { redirect_to web_service_logs_url }
      format.json { head :ok }
    end
  end
end
