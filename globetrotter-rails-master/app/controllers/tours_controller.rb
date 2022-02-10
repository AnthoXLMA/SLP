# frozen_string_literal: true

class ToursController < ApplicationController
  before_action :set_tour, only: %i[show edit update destroy]
  before_action :check_admin_or_authorized_guide!, except: %i[events show index]
  def show
    if (!@tour.published || !@tour.guide.published) && !current_user&.admin? && !(current_user&.guide? && @tour.guide.user_id == current_user.id)
      raise UnauthorizedException
    end

    @tours = Tour.suggested(current_user) { |p| p.where.not(id: params[:id]) }
    @user_event_registrations_by_event_id =
      if current_user
        current_user.allow_strict_loading do
          current_user.event_registrations.group_by(&:event_id)
        end
      else
        {}
      end
    @last_event_registration = @tour.past_registrations_for_user(current_user).includes(:event).take(1).first
    @comment = @last_event_registration && (@last_event_registration.comment || @last_event_registration.build_comment)

    # allow devise to redirect to this tour after sign in (if the user clicks on the register button)
    store_location_for(:user, tour_path(@tour)) unless current_user
  end

  def new
    @tour = Tour.new
    @suggested_guide_id = params.permit(:guide_id)[:guide_id] if current_user.admin?
  end

  def create
    @tour = Tour.new(tour_params[:tour])
    @tour.guide_id = if current_user.admin?
                       params[:tour]&.[](:guide_id)
                     else
                       current_user.allow_strict_loading do
                         current_user.guide.id
                       end
                     end

    respond_to do |format|
      if @tour.save
        format.html { redirect_to tour_path(@tour), notice: 'Tour was successfully updated.' }
        format.json { render :show, status: :ok, location: @tour }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tour.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    respond_to do |format|
      @tour.allow_strict_loading do
        if @tour.update(tour_params[:tour])
          format.html { redirect_to tour_path(@tour), notice: 'Tour was successfully updated.' }
          format.json { render :show, status: :ok, location: @tour }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tour.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def index
    raise UnauthorizedException unless current_user&.guide? || current_user&.admin?

    @tours = Tour.for(current_user)
    @title = '.'

    if params[:all_guides]
      raise UnauthorizedException unless current_user&.admin?

      @title += 'all'
    else
      @title += 'my'
      @tours = @tours.where('guides.user_id' => current_user.id)
    end

    if params[:unpublished]
      @title += '-unpublished'
      @tours = @tours.unpublished
    end
    @title += '-tours'

    @tours = @tours.includes(guide: [:user, { image_attachment: :blob }])
                   .includes(:next_event)
                   .includes(thumbnail_attachment: :blob)
  end

  DAY_IDS = Array.new(7, &:to_s)
  def events
    @topic_list = %i[nature city heritage gastronomy people traditions architecture history]
    @filter_type = params[:filter_type]&.to_sym
    @language = params[:language] || current_user&.tour_language
    # includes: load the dependent objects, avoiding n+1 queries
    @events = Event.for(current_user)
                   .includes(tour: [{
                               guide: [
                                 :user,
                                 { image_attachment: :blob }
                               ],
                               thumbnail_attachment: :blob
                             }])
                   .where(cancelled_date: nil)
                   .where('date > ?', Time.now)
                   .where('tours.published = true')
                   .order('events.date')
                   .references('tours')
    @events = @events.where('tours.language' => @language) if @language && @language.any?
    @filter_type ||= :date
    case @filter_type
    when :date
      @filter_by_date = params.permit(:start_date, :end_date, :timeofday_begin, :timeofday_end, dayofweek: [])
      @filter_by_date.reject! { |_, v| v.nil? || v.empty? }
      @events = @events.with_date_in_range(
        @filter_by_date[:start_date]..@filter_by_date[:end_date]
      )
      @events = @events.with_hour_of_day_in_range(
        @filter_by_date[:timeofday_begin]..@filter_by_date[:timeofday_end]
      )
      @filter_by_date[:dayofweek] ||= DAY_IDS
      @events = @events.with_day_of_week_not_in(
        DAY_IDS - @filter_by_date[:dayofweek]
      )
    when :location
      @filter_by_location = params.permit(:location, :region, :country, :city)
      region = @filter_by_location[:region]
      possible_countries = region && !region.empty? && countries_by_region[region] || countries
      @options = {
        region: regions.zip(regions),
        country: possible_countries.map { |c| [c.country, c.code] },
        city: []
      }
      @events = @events.joins(tour: :country)
      if @filter_by_location[:location] && !@filter_by_location[:location].empty?
        @events = @events.where("? <<% (country || ' ' || title || ' ' || subtitle)", @filter_by_location[:location])
      end
      if @filter_by_location[:region] && !@filter_by_location[:region].empty?
        @events = @events.where('tours.country': possible_countries)
      end
      if @filter_by_location[:country] && !@filter_by_location[:country].empty?
        if possible_countries.map(&:code).include?(@filter_by_location[:country])
          @events = @events.where('tours.country': countries_by_code[@filter_by_location[:country]]&.first)
        else
          @filter_by_location.delete(:country)
        end
      end
    when :topic
      @filter_by_topic = params.permit(:topic, *@topic_list)
    end
    @events = @events.limit(100).uniq(&:tour_id).first(20)
  end

  private

  def set_tour
    @tour = Tour.for(current_user)
                .includes(image_attachment: :blob)
                .includes(thumbnail_attachment: :blob)
                .includes(guide: [:user, { image_attachment: :blob }])
                .includes(:future_events)
                .includes(comments: { event_registration: :user })
                .find(params[:id])
    raise RecordNotFound unless @tour
  end

  def tour_params
    if current_user&.admin?
      params.permit(tour: %i[title subtitle duration short_description description image thumbnail country_id language
                             published])
    else
      params.permit(tour: %i[title subtitle duration short_description description image thumbnail country_id language])
    end
  end

  def guide_params
    params.permit(tour: %i[guide_id])
  end

  def local_date(iso_str)
    @tz ? @tz.iso8601(iso_str) : Date.iso8601(iso_str)
  end

  def timezone
    Time.zone.tzinfo.name
  end

  def countries
    @countries ||= Country.order(:country).where('exists (SELECT 1 FROM tours WHERE countries.id = tours.country_id)')
  end

  def countries_by_region
    @countries_by_region ||= countries.group_by(&:region)
  end

  def countries_by_code
    countries.group_by(&:code)
  end

  def regions
    @regions ||= countries_by_region.keys.sort.uniq
  end

  def check_admin_or_authorized_guide!
    authenticate_user!
    raise UnauthorizedException unless current_user.guide? || current_user.admin?

    raise UnauthorizedException if @tour && !current_user.admin? && @tour.guide.user_id != current_user.id
  end
end
