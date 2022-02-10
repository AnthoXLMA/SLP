# frozen_string_literal: true

class User::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    self.resource = User.new(timezone: Time.zone.name, language: I18n.locale, tour_language: [I18n.locale],
                             accept_google_analytics: @accept_google_analytics)
    respond_with resource
  end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  def edit
    resource.timezone ||= Time.zone.name
    resource.language ||= I18n.locale
    resource.accept_google_analytics ||= @accept_google_analytics
  end

  def create
    build_resource(sign_up_params)

    if params[:accept_terms_and_conditions]
      resource.save
    else
      resource.errors.add(:base, message: t('application.accept_terms_and_conditions.errors'))
    end
    yield resource if block_given?
    if resource.persisted?
      set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # PUT /resource
  # def update
  #   super
  # end

  def after_update_path_for(_resource)
    edit_user_registration_path(locale: resource&.language)
  end

  # DELETE /resource
  def destroy
    # load dependent objects because they will all be deleted or soft-deleted
    user = User.includes(
      guide: {
        tours: {
          events: :event_registrations # soft deleted
        }
      },
      event_registrations: :comment # hard deleted
    ).find(current_user.id)
    user.soft_delete

    # disable destroy for that user so that we can call super
    def current_user.destroy; end
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: [:firstname, :lastname, :birthdate, :nationality,
                                             :country, :timezone, :language, :accept_google_analytics,
                                             { tour_language: [] }])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: [:firstname, :lastname, :birthdate, :nationality,
                                             :country, :timezone, :language, :accept_google_analytics,
                                             { tour_language: [] }])
  end

  # allow update without password
  def update_resource(resource, params)
    if params.include?(:current_password) || params.include?(:password)
      resource.update_with_password(params)
    else
      resource.update(params)
    end
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
