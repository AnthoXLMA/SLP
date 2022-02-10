# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]
  before_action :require_user_to_be_the_author, only: %i[update destroy]

  def create
    @comment = Comment.new(comment_params)
    @comment.allow_strict_loading do
      raise UnauthorizedException, 'Comments for future events are forbidden' if @comment.event.date > Time.now

      if @comment.event_registration_id
        registration = @comment.event_registration
        raise UnauthorizedException, 'Bad user' unless current_user.id == registration.user_id
        raise UnauthorizedException, "You can only comment a tour that you've attended" unless registration.visited?
      end

      respond_to do |format|
        if @comment.save

          format.html do
            redirect_to tour_path(@comment.event.tour_id), notice: 'Comment was successfully created.'
          end
          format.json { render :show, status: :created, location: @comment }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @comment.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    registration = @comment.event_registration
    raise UnauthorizedException, "You can only comment a tour that you've attended" unless registration.visited?

    respond_to do |format|
      if @comment.update(params.require(:comment).permit(:comment, :rating))
        event = @comment.allow_strict_loading(&:event)
        format.html do
          redirect_to tour_path(event.tour_id), notice: 'Comment was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html do
        @comment.allow_strict_loading do
          redirect_to tour_path(@comment.event.tour_id), notice: 'Comment was successfully destroyed.'
        end
      end
      format.json { head :no_content }
    end
  end

  private

  def set_comment
    @comment = Comment.includes(event_registration: :event).find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:comment, :rating, :event_registration_id)
  end

  def require_user_to_be_the_author
    authenticate_user!
    set_comment
    raise UnauthorizedException if @comment.event_registration.user_id != current_user.id
  end
end
