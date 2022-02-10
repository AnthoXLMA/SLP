# frozen_string_literal: true

class EventNotStartedException < StandardError; end

class EventAlreadyFinishedException < StandardError; end

class EventCancelledException < StandardError; end

class MissingMeetingDetailsException < StandardError; end

class EventsController < ApplicationController
  before_action :set_tour, only: %i[index new create]
  before_action :set_event, only: %i[show edit update]
  before_action :set_event_for_destroy, only: %i[destroy]
  before_action :authenticate_user!, except: [:index]
  before_action :check_authorized_to_edit!, except: %i[index show]

  include Zoom::API
  include Zoom::WebClient

  # GET /events/1 or /events/1.json
  def show
    raise RecordNotFound unless @event
    raise EventAlreadyFinishedException if @event.past?
    raise EventNotStartedException if @event.future?
    raise EventCancelledException if @event.cancelled?
    raise MissingMeetingDetailsException unless @event.zoom_meeting_details
    raise UnauthorizedException unless current_user&.admin? || (@event.tour.published && @event.tour.guide.published)

    @api_key = Rails.application.credentials.zoom[:api_key]
    @api_secret = Rails.application.credentials.zoom[:api_secret]
    @user_name = current_user.firstname || 'Anonymous Globetrotter'
    @user_email = ''
    @meeting_number = @event.zoom_meeting_details.fetch('id')
    @meeting_password = @event.zoom_meeting_details.fetch('password')
    @role = 0
    @signature = generate_signature(@meeting_number, @role)

    # mark the eventregistration as visited
    e = EventRegistration.find_or_initialize_by(user: current_user, event: @event)
    e.visited_date = Time.now
    e.save!
    @meeting_leave_url = after_event_event_registration_path(e)
    render :show, layout: 'zoom'
  rescue EventNotStartedException
    flash.notice = t('event.not_started',
                     date: l(@event.date, format: :long_with_day),
                     start_date: l(@event.live_start_date, format: :long_with_day))
    render :show, status: 400
  rescue EventAlreadyFinishedException
    flash.notice = t('event.already_finished')
    render :show, status: 400
  rescue MissingMeetingDetailsException
    flash.notice = t('event.missing_details')
    render :show, status: 400
  rescue EventCancelledException
    raise ActiveRecord::RecordNotFound
  end

  # GET /events/new
  def new
    raise RecordNotFound unless @tour

    @event = @tour.events.build
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params.merge(tour_id: params[:tour_id]))
    @event.allow_strict_loading do
      @event.tour.allow_strict_loading do
        # set guide_id on event too
        # There is a gist index on PG to check that the guide is available
        @event.guide_id = @event.tour.guide_id

        # assign a license
        @event.zoom_license_id = @event.preferred_license_id

        if @event.zoom_license_id
          @event.zoom_meeting_details = create_meeting(
            @event.zoom_license.zoom_user_id,
            @event.date,
            topic: @event.tour.title
          )
        end

        respond_to do |format|
          if @event.save
            @event.tour.allow_strict_loading do
              @event.tour.guide.allow_strict_loading do
                application_mailer
                  .with({ user_id: @event.tour.guide.user_id, event_id: @event.id })
                  .event_about_to_start
                  .deliver_later(wait_until: @event.date - Event::BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES.minutes)
                application_mailer
                  .with({ event_id: @event.id })
                  .event_scheduled
                  .deliver_later
                NextEvent.refresh

                format.html { redirect_to @event.tour, notice: 'Event was successfully created.' }
                format.json { render :show, status: :created, location: @event }
              end
            end
          else
            set_tour
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @event.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    raise EventAlreadyFinishedException if @event.past?
    raise EventCancelledException if @event.cancelled?

    @event.cancel_and_save(application_mailer)
    zoom_meeting_id = @event.zoom_meeting_details&.fetch('id', nil)
    delete_meeting(zoom_meeting_id) if zoom_meeting_id
    NextEvent.refresh

    redirect_back fallback_location: tour_path(@event.tour_id), notice: 'Event was successfully cancelled.'
  rescue EventAlreadyFinishedException
    redirect_back fallback_location: tour_path(@event.tour_id), notice: 'Event can not be cancelled because it already happened.',
                  status: 400
  rescue EventCancelledException
    redirect_back fallback_location: tour_path(@event.tour_id), notice: 'Event is already cancelled.',
                  status: 400
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tour
    @tour = Tour.for(current_user).includes(:guide).find(params[:tour_id])
  end

  def set_event
    @event = Event.for(current_user).includes(tour: :guide).find(params[:id])
  end

  def set_event_for_destroy
    @event = Event.for(current_user).includes(tour: :guide, event_registrations: {}).find(params[:id])
    raise RecordNotFound unless @event
  end

  # Only allow a list of trusted parameters through.
  def event_params
    params.require(:event).permit(:date)
  end

  def check_authorized_to_edit!
    allowed = current_user.admin? || (current_user.guide? && (@tour || @event.tour).guide.user_id == current_user.id)
    raise UnauthorizedException unless allowed
  end

  def application_mailer
    ApplicationMailer
  end
end
