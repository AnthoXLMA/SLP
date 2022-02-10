# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    return render :reload_timezone unless @tz

    @controller = :welcome
    @tours = Tour.suggested(current_user)
  end
end
