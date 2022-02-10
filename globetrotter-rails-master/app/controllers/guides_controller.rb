# frozen_string_literal: true

class GuidesController < ApplicationController
  before_action :set_guide_full, only: %i[show]
  before_action :set_guide, only: %i[edit update]
  before_action :authenticate_user!, except: %i[show]
  before_action :check_admin_or_authorized_guide!, except: %i[show]
  def show
    # do not display unpublished guides unless admin or authorized guide
    check_admin_or_authorized_guide! unless @guide.published

    @user_event_registrations_by_event_id =
      if current_user
        current_user.event_registrations
                    .includes(event: :tour)
                    .references(:tours)
                    .where('tour.guide_id': @guide.id)
                    .all
                    .group_by(&:event_id)
      else
        {}
      end
  end

  def edit; end

  def update
    respond_to do |format|
      if @guide.update(guide_params[:guide] || {})
        format.html { redirect_to guide_path(@guide), notice: 'Guide was successfully updated.' }
        format.json { render :show, status: :ok, location: @guide }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @guide.errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    raise UnauthorizedException unless current_user&.admin?

    @guides = Guide.for(current_user).includes(:user).joins(:user).all.order('users.firstname', 'users.lastname')
  end

  def new
    raise UnauthorizedException unless current_user&.admin?

    @guide = Guide.new
  end

  def create
    raise UnauthorizedException unless current_user&.admin?

    @guide = Guide.new(guide_params[:guide])

    respond_to do |format|
      if @guide.save
        format.html do
          redirect_to guide_path(@guide), notice: 'Guide was successfully created.'
        end
        format.json { render :show, status: :created, location: @guide }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @guide.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @guide = Guide.for(current_user).includes(tours: { events: :event_registrations })
                  .find(params[:id])
    raise ActiveRecord::RecordNotFound unless @guide

    @guide.soft_delete
    respond_to do |format|
      format.html do
        redirect_to guides_path, notice: 'Guide was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  def set_guide
    @guide = Guide.for(current_user).includes(:user).find(params[:id])
    raise ActiveRecord::RecordNotFound unless @guide
  end

  def set_guide_full
    @guide = Guide.for(current_user)
                  .includes(image_attachment: :blob)
                  .includes(:user)
                  .includes(future_events: :tour)
                  .includes(tours: [:next_event, { thumbnail_attachment: :blob }])
                  .includes(comments: { event_registration: :user })
                  .find(params[:id])
    raise ActiveRecord::RecordNotFound unless @guide
  end

  def guide_params
    if current_user&.admin?
      params.permit(guide: %i[published user_id short_description description location topics image])
    else
      params.permit(guide: %i[short_description description location topics image])
    end
  end

  def check_admin_or_authorized_guide!
    authenticate_user!
    raise UnauthorizedException unless current_user.guide? || current_user.admin?

    raise UnauthorizedException if @guide && !current_user.admin? && @guide.user_id != current_user.id
  end
end
