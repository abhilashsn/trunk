class MpiStatisticsReportsController < ApplicationController
  require_role "admin"

  # GET /mpi_statistics_reports
  # GET /mpi_statistics_reports.json
  def index
    @mpi_statistics_reports = MpiStatisticsReport.includes({:batch => [:client, :facility]}, :user, {:eob => :check_information}).limit(20).order("id desc")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mpi_statistics_reports }
    end
  end

  # GET /mpi_statistics_reports/1
  # GET /mpi_statistics_reports/1.json
  def show
    @mpi_statistics_report = MpiStatisticsReport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mpi_statistics_report }
    end
  end

  # GET /mpi_statistics_reports/new
  # GET /mpi_statistics_reports/new.json
  def new
    @mpi_statistics_report = MpiStatisticsReport.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mpi_statistics_report }
    end
  end

  # GET /mpi_statistics_reports/1/edit
  def edit
    @mpi_statistics_report = MpiStatisticsReport.find(params[:id])
  end

  # POST /mpi_statistics_reports
  # POST /mpi_statistics_reports.json
  def create
    @mpi_statistics_report = MpiStatisticsReport.new(params[:mpi_statistics_report])

    respond_to do |format|
      if @mpi_statistics_report.save
        format.html { redirect_to @mpi_statistics_report, notice: 'Mpi statistics report was successfully created.' }
        format.json { render json: @mpi_statistics_report, status: :created, location: @mpi_statistics_report }
      else
        format.html { render action: "new" }
        format.json { render json: @mpi_statistics_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /mpi_statistics_reports/1
  # PUT /mpi_statistics_reports/1.json
  def update
    @mpi_statistics_report = MpiStatisticsReport.find(params[:id])

    respond_to do |format|
      if @mpi_statistics_report.update_attributes(params[:mpi_statistics_report])
        format.html { redirect_to @mpi_statistics_report, notice: 'Mpi statistics report was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @mpi_statistics_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mpi_statistics_reports/1
  # DELETE /mpi_statistics_reports/1.json
  def destroy
    @mpi_statistics_report = MpiStatisticsReport.find(params[:id])
    @mpi_statistics_report.destroy

    respond_to do |format|
      format.html { redirect_to mpi_statistics_reports_url }
      format.json { head :ok }
    end
  end
end
