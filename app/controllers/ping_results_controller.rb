class PingResultsController < ApplicationController
  include Requested
  before_action :set_ping_result, only: [:show, :edit, :update, :destroy]

  # GET /ping_results/recent
  def recent
    server = Location.where(host: host_on_header).order(updated_at: :desc).first
    @ping_results = server ? PingResult.where(server_location_id: server.id).where.not(distance_km: nil).order(updated_at: :desc).limit(100) : []
  end

  # GET /ping_results
  # GET /ping_results.json
  def index
    @ping_results = PingResult.all
  end

  # GET /ping_results/1
  # GET /ping_results/1.json
  def show
  end

  # GET /ping_results/new
  def new
    @ping_result = PingResult.new
  end

  # GET /ping_results/1/edit
  def edit
  end

  # POST /ping_results
  # POST /ping_results.json
  def create
    @ping_result = PingResult.new(ping_result_params)
    @ping_result.user_agent = user_agent_on_header
    @ping_result.protocol = protocol_on_request
    @ping_result.distance_km = nil

    respond_to do |format|
      if check_and_create
        format.html { redirect_to @ping_result, notice: 'Ping result was successfully created.' }
        format.json { render :show, status: :created, location: @ping_result }
      else
        format.html { render :new }
        format.json { render json: @ping_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ping_results/1
  # PATCH/PUT /ping_results/1.json
  def update
    respond_to do |format|
      if @ping_result.update(ping_result_params)
        format.html { redirect_to @ping_result, notice: 'Ping result was successfully updated.' }
        format.json { render :show, status: :ok, location: @ping_result }
      else
        format.html { render :edit }
        format.json { render json: @ping_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ping_results/1
  # DELETE /ping_results/1.json
  def destroy
    @ping_result.destroy
    respond_to do |format|
      format.html { redirect_to ping_results_url, notice: 'Ping result was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ping_result
      @ping_result = PingResult.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ping_result_params
      params.require(:ping_result).permit(:lag_ms, :user_agent, :location_id, :server_location_id, :protocol, :distance_km)
    end

    # Measure the distance and update the @ping_result after validation
    def check_and_create
      client = Location.where(host: src_addr_on_header).order(updated_at: :desc).first
      return false if not client or client.id != @ping_result.location_id
      server = Location.where(host: host_on_header).order(updated_at: :desc).first
      return false if not server or server.id != @ping_result.server_location_id
      @ping_result.measure_distance!
      return @ping_result.save
    end
end
