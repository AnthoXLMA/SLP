# frozen_string_literal: true

require 'test_helper'

class EventRegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @past_event_registration = event_registrations(:event_registration_one)
    @future_event_registration = event_registrations(:event_registration_three)
    @valid_event_registration_params = {
      event_registration: {
        event_id: events(:event_two).id
      }
    }
    @invalid_event_registration_params = {
      event_registration: {
        event_id: 'invalid_id'
      }
    }
  end

  def run
    # stub method from Zoom::API
    @mock_controller = EventRegistrationsController.new
    EventRegistrationsController.stub :new, @mock_controller do
      super
    end
  end

  def mock_mailer
    @mock_mailer = Minitest::Mock.new
    @mock_controller.stub(:application_mailer, @mock_mailer) do
      yield @mock_mailer
    end
    @mock_mailer.verify
  end

  def assert_redirect_with_error(url, user, error)
    assert_redirected_to url
    get url # follow redirect
    I18n.with_locale(user.language) do
      assert_select '.messages > .alert.warning', /#{I18n.t('registration.unsuccessfull', reason: error)}/
    end
  end

  def last_event_registration
    er = EventRegistration.last
    er.instance_variable_set(:@strict_loading, false)
    er.event&.instance_variable_set(:@strict_loading, false)
    er
  end

  ##############################
  #          INDEX            #
  ##############################
  test 'it is required to be authenticated' do
    get event_registrations_url

    assert_redirected_to new_user_session_url
  end
  test 'it is available to normal users' do
    user = users(:user_one)
    sign_in user
    get event_registrations_url

    assert_response :success
  end

  test 'cancelled tours are not suggested' do
    user = users(:user_one)
    tour = Tour.includes(events: :event_registrations).find(tours(:tour_two).id)
    sign_in user
    user.tour_language = [:en, :fr]
    user.save!

    get event_registrations_url
    assert_select ".header > a[href=\"#{tour_path(tour)}\"]", 1
    tour.events.each { |e| e.cancel_and_save }
    NextEvent.refresh
    get event_registrations_url
    assert_select ".header > a[href=\"#{tour_path(tour)}\"]", 0
  end
  ##############################
  #          CREATE            #
  ##############################
  test 'it is required to be authenticated to create an event_registration' do
    assert_difference('EventRegistration.count', 0) do
      post event_registrations_path, params: @valid_event_registration_params
    end

    assert_redirected_to new_user_session_url
  end
  test 'it is possible for a normal user to create a event_registration' do
    sign_in users(:user_one)
    assert_difference('EventRegistration.count', 1) do
      post event_registrations_path, params: @valid_event_registration_params
    end

    assert_redirected_to tour_url(last_event_registration.tour)
  end
  test 'if the params are invalid, an error is returned' do
    sign_in users(:admin)
    assert_difference('EventRegistration.count', 0) do
      post event_registrations_path, params: @invalid_event_registration_params
    end

    assert_redirect_with_error(welcome_path, users(:admin), 'Event must exist')
  end
  test 'it is not possible to register twice to the same event' do
    sign_in users(:user_one)
    event = events(:event_two)
    assert_difference('EventRegistration.count', 1) do
      post event_registrations_path, params: @valid_event_registration_params
    end
    assert_difference('EventRegistration.count', 0) do
      post event_registrations_path, params: @valid_event_registration_params
    end

    assert_redirect_with_error(
      tour_path(event.tour_id),
      users(:user_one),
      'User already registered to this event'
    )
  end
  test 'it is not possible to register to a cancelled event' do
    sign_in users(:user_one)

    event = Event.includes(:event_registrations).find(events(:event_two).id)
    event.cancel_and_save

    assert_difference('EventRegistration.count', 0) do
      post event_registrations_path(locale: 'fr'), params: @valid_event_registration_params
    end

    assert_redirect_with_error(
      tour_path('fr', event.tour_id),
      users(:user_one),
      "L'évènement est annulé"
    )
  end

  ##############################
  #          DESTROY           #
  ##############################
  test 'it is required to be authenticated to destroy an event_registration' do
    delete event_registration_path(@future_event_registration)

    assert_redirected_to new_user_session_url
  end
  test 'it is possible to destroy an event_registration' do
    user = users(:user_one)
    sign_in user

    mock_mailer do |mailer|
      mailer.expect(:with, mailer, [{ event_registration_id: @future_event_registration.id }])
      mailer.expect(:event_cancellation, mailer)
      mailer.expect(:deliver_now, nil)
      assert_difference('EventRegistration.count', -1) do
        delete event_registration_path(@future_event_registration)
      end
    end

    @future_event_registration.instance_variable_set(:@strict_loading, false)
    @future_event_registration&.event&.instance_variable_set(:@strict_loading, false)
    assert_redirected_to tour_url(@future_event_registration.tour)
  end
  test "it is not possible to destroy someone else's event_registration" do
    user = users(:user_two)
    sign_in user

    assert_difference('EventRegistration.count', 0) do
      delete event_registration_path(@future_event_registration)
    end

    assert_response 403
  end
  test 'it is not possible to unregister from a past tour' do
    sign_in users(:user_one)

    assert_difference('EventRegistration.count', 0) do
      delete event_registration_path(@past_event_registration)
    end

    assert_response 403
  end
end
