# frozen_string_literal: true

class GuideEventsController < ApplicationController
  before_action :check_admin_or_guide!
  def index
    @events = Event.for(current_user)
                   .includes(tour: { guide: :user, thumbnail_attachment: :blob }).where('date > ?',
                                                                                        Time.now.round).order(date: :asc)
    return if current_user.admin? && params[:show_all]

    @events = @events.where(tours: { guides: { user_id: current_user.id } })
  end

  def show
    @event = Event.for(current_user)
                  .includes(zoom_license: {}, tour: { guide: {}, thumbnail_attachment: :blob }).find(params[:id])
    return UnauthorizedException unless current_user.admin? || current_user.id == @event&.tour&.guide&.user_id
  end

  private

  def check_admin_or_guide!
    authenticate_user!
    raise UnauthorizedException if !current_user.guide? && !current_user.admin?
  end
end
