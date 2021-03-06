require "ice_cube"
include ActionView::Helpers::NumberHelper
class ClientRequestsController < ApplicationController
  def match_applicant
    @client_request = ClientRequest.find(params[:id])
    if @client_request.update_attribute("matched_user", params[:matched_id])
      @client_request.applicants.clear()
    end
    redirect_to client_request_path(@client_request)
  end

  def index
	@filterrific =  initialize_filterrific(ClientRequest,params[:filterrific],
		select_options: {
			sorted_by: ClientRequest.options_for_sorted_by,
			with_name: ServiceType.options_for_select
		},
	  persistence_id: 'shared_key',
      default_filter_params: {},
	) or return
	
	@client_requests = @filterrific.find.page(params[:page])

	respond_to do |format|
		format.html
		format.js
	end
	rescue ActiveRecord::RecordNotFound => e
	# There is an issue with the persisted param_set. Reset it.
	puts "Had to reset filterrific params: #{ e.message }"
	redirect_to(reset_filterrific_url(format: :html)) and return
  end

  def new
    require_logged_in()
    @client_request = ClientRequest.new
  end
  # An IceCube rule(period_detail) and a start date (period) is used to denote the days that an offering or request are
  # available.
  # return [{offering: teen_offering, occur_date: date}], offerings that match the given client_request
  def match_offerings(client_request)
    def occurrences(event)
      if event.rule.nil?
        [event.period]
      else
        schedule = IceCube::Schedule.new([event.period, Time.now.beginning_of_day].max)
        schedule.add_recurrence_rule event.rule
        schedule.occurrences([event.period, Time.now.beginning_of_day].max + 1.year)
      end
    end
    def match_occurrences(base, matcher)
      matcher_occurrence = occurrences(matcher)
      schedule = IceCube::Schedule.new([base.period, Time.now.beginning_of_day].max)
      unless base.rule.nil?
        schedule.add_recurrence_rule base.rule
      end
      for occur_time in matcher_occurrence
        if schedule.occurs_on? occur_time.to_date
          return {offering: matcher, occur_date: occur_time.to_date}
        end
      end
      nil
    end
    offerings = TeenOffering.where(service_type_id: client_request.service_type_id)
    matched = []
    for offering in offerings
      matched_occurrences = match_occurrences(client_request, offering)
      unless matched_occurrences.nil?
        matched << matched_occurrences
      end
    end
    matched
  end

  def show
    @client_request = ClientRequest.find(params[:id])
    @matched_offerings = match_offerings(@client_request)
    @message = Message.new()
    @messages = @client_request.messages
    if @client_request.matched_user?
      @matched_user = Account.find(@client_request.matched_user)
    end
    if session[:user_id]
      @username = logged_in_user_or_guest().username
    else
      @username = "Please log in first."
    end
  end

  def edit
    @client_request = ClientRequest.find(params[:id])
  end

  def destroy
    @client_request = ClientRequest.find(params[:id])
    @client_request.destroy

    redirect_to client_requests_path
  end

  def update
    @client_request = ClientRequest.find(params[:id])

    if @client_request.update(client_request_params)
      redirect_to @client_request
    else
      render 'edit'
    end
  end

  def create
    if require_logged_in()
      @client_request = ClientRequest.new(client_request_params)
      @client_request.account_id = logged_in_user_or_guest.id
	  @client_request.service_name = ServiceType.find(@client_request.service_type_id).name
      if @client_request.save
        redirect_to @client_request
      else
        render 'new'
      end
    end
  end

  private
  def client_request_params
    params.require(:client_request).permit(:service_type_id, :period, :detail, :period_detail)
  end
end
