# frozen_string_literal: true

class UnauthorizedException < RuntimeError
end

class ApplicationController < ActionController::Base
  http_basic_authenticate_with **Rails.application.credentials.http_basic_authenticate if Rails.env.production?
  around_action :switch_locale, :switch_timezone, :catch_exceptions
  before_action :set_accept_google_analytics

  def catch_exceptions
    yield
  rescue UnauthorizedException => e
    Rails.logger.debug "403: #{e.message}:#{e.message}\n#{e.backtrace.join("\n")}"
    render '403', status: 403
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.debug "404: #{e.class}:#{e.message}\n#{e.backtrace.join("\n")}"
    render '404', status: 404
  rescue ActionController::ParameterMissing, ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey => e
    Rails.logger.debug "400: #{e.class}:#{e.message}\n#{e.backtrace.join("\n")}"
    render '400', status: 400
  end

  def switch_locale(&action)
    locale = preferred_locale
    return yield unless locale
    cookies['locale'] = locale
    I18n.with_locale(locale, &action)
  end

  def switch_timezone(&action)
    @tz = preferred_tz
    return yield unless @tz

    cookies['tz'] = @tz.tzinfo.name
    Time.use_zone(@tz, &action)
  end

  protected

  def after_sign_in_path_for(resource)
    welcome_path(locale: resource&.language)
  end

  def params_locale
    locale = params.delete(:locale)&.first(2)&.to_sym
    return nil unless locale && I18n.available_locales.include?(locale)

    locale
  end

  def cookie_locale
    locale = cookies['locale']&.to_sym
    unless locale && I18n.available_locales.include?(locale)
      cookies.delete('locale')
      return nil
    end

    locale
  end

  def user_locale
    current_user&.language
  end

  def http_header_locale
    http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def preferred_locale
    params_locale || user_locale || cookie_locale || http_header_locale
  end

  def cookie_tz
    tz = cookies['tz']
    return nil unless tz

    ActiveSupport::TimeZone.new(tz)
  end

  def params_tz
    tz = params.delete(:tz)
    return nil unless tz

    ActiveSupport::TimeZone.new(tz)
  end

  def user_tz
    return nil unless current_user&.timezone

    ActiveSupport::TimeZone.new(current_user.timezone)
  end

  def preferred_tz
    params_tz || user_tz || cookie_tz
  end

  def params_accept_google_analytics
    params.delete('accept_google_analytics')&.to_sym
  end

  def user_accept_google_analytics
    current_user&.accept_google_analytics&.to_sym
  end

  def cookie_accept_google_analytics
    cookies['accept_google_analytics']&.to_sym
  end

  def set_accept_google_analytics
    @accept_google_analytics = params_accept_google_analytics || user_accept_google_analytics || cookie_accept_google_analytics
    unless @accept_google_analytics.nil?
      cookies['accept_google_analytics'] = @accept_google_analytics
      if current_user && current_user.accept_google_analytics != @accept_google_analytics
        current_user.accept_google_analytics = @accept_google_analytics
        current_user.save!
      end
    end
  end

  def default_url_options
    super.merge(locale: I18n.locale)
  end
end
