# frozen_string_literal: true

require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @event = events(:event_two)
    @stub_zoom_meeting_details = {
      created_from_ut: true
    }
    @tour_guide_one = tours(:tour_one)
    @tour_guide_two = tours(:tour_two)
    @tour_guide_three = tours(:tour_three)
    @valid_event_params_guide_one = {
      event: {
        tour_id: @tour_guide_one.id,
        date: Time.now.round + 5.minutes
      }
    }
    @valid_event_params_guide_two = {
      event: {
        tour_id: @tour_guide_two.id,
        date: Time.now.round + 5.minutes
      }
    }
    @valid_event_params_guide_three = {
      event: {
        tour_id: @tour_guide_three.id,
        date: Time.now.round + 5.minutes
      }
    }
  end

  def run
    # stub method from Zoom::API
    @mock_controller = EventsController.new
    EventsController.stub :new, @mock_controller do
      @mock_controller.stub(:create_meeting, @stub_zoom_meeting_details) do
        super
      end
    end
  end

  def mock_mailer
    @mock_mailer = Minitest::Mock.new
    @mock_controller.stub(:application_mailer, @mock_mailer) do
      yield @mock_mailer
    end
    @mock_mailer.verify
  end

  ############################
  #        SHOW              #
  ############################
  test 'it requires the user to be authenticated to view an event' do
    get event_path(@event)

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to connect to an event' do
    sign_in users(:user_one)
    get event_path(@event)

    assert_response 200, response.body
  end

  test 'it is possible to connect to an event as a guide' do
    sign_in users(:guide_one)
    get event_path(@event)

    assert_response 200
  end

  test 'it is possible to connect to an event as an admin' do
    sign_in users(:admin)
    get event_path(@event)

    assert_response 200
  end

  test 'when already registered to an event, it mark the event_registration as visited' do
    user = users(:user_two)
    event = events(:event_two)

    # event has not yet been visited
    er = EventRegistration.find_by(user: user, event: event)
    assert(!er.visited?)

    sign_in user
    get event_path(event)
    assert_response 200

    # after visit: event is marked as visited
    er = EventRegistration.find_by(user: user, event: event)
    assert(er.visited?)
  end

  test 'when not registered to an event, it creates an event_registration as visited' do
    user = users(:user_one)
    event = events(:event_two)

    # event has not yet been visited
    er = EventRegistration.find_by(user: user, event: event)
    assert(er.nil?)

    sign_in user
    get event_path(event)
    assert_response 200

    # after visit: event is marked as visited
    er = EventRegistration.find_by(user: user, event: event)
    assert(er.visited?)
  end

  ############################
  #        NEW               #
  ############################
  test 'it requires the user to be authenticated to get the form to create an event' do
    get new_tour_event_path(@tour_guide_one)

    assert_redirected_to new_user_session_url
  end

  test 'an admin can get the form to create an event' do
    sign_in users(:admin)

    get new_tour_event_path(@tour_guide_one)
    assert_response 200
  end

  test 'a guide can get the form to create an event' do
    sign_in users(:guide_one)

    get new_tour_event_path(@tour_guide_one)
    assert_response 200
  end

  test 'only the guide registered for the tour can get the form to create an event' do
    sign_in users(:guide_two)

    get new_tour_event_path(@tour_guide_one)
    assert_response 403
  end

  ############################
  #        CREATE            #
  ############################
  test 'it requires the user to be authenticated to to create an event' do
    assert_difference('Event.count', 0) do
      post tour_events_path(@tour_guide_one, @valid_event_params_guide_one)
    end

    assert_redirected_to new_user_session_url
  end

  test 'an admin can create an event' do
    sign_in users(:admin)

    assert_difference('Event.count', 1) do
      post tour_events_path(@tour_guide_one, @valid_event_params_guide_one)
    end
    assert_redirected_to tour_url(@tour_guide_one)
  end

  test 'the date can be sent in iso format' do
    sign_in users(:admin)
    params = {
      event: {
        date: '2050-08-30T12:00:00Z'
      }
    }

    assert_difference('Event.count', 1) do
      post tour_events_path(@tour_guide_one, params.merge(tz: 'Paris'))
    end
    assert_redirected_to tour_url(@tour_guide_one)
    assert_in_delta Time.utc(2050, 8, 30, 12, 0), Event.last.date, 60
  end

  test 'the timezone is supported' do
    sign_in users(:admin)
    params = {
      event: {
        date: '2050-08-30T12:00'
      }
    }

    assert_difference('Event.count', 1) do
      post tour_events_path(@tour_guide_one, params.merge(tz: 'Paris'))
    end
    assert_redirected_to tour_url(@tour_guide_one)
    assert_in_delta Time.utc(2050, 8, 30, 12, 0), Event.last.date + 2.hour, 60
  end

  test 'the timezone is supported (daylight saving)' do
    sign_in users(:admin)
    params = {
      event: {
        'date(1i)': 2050,
        'date(2i)': 1,
        'date(3i)': 30,
        'date(4i)': 12,
        'date(5i)': 0
      }
    }

    assert_difference('Event.count', 1) do
      post tour_events_path(@tour_guide_one, params.merge(tz: 'Paris'))
    end
    assert_redirected_to tour_url(@tour_guide_one)
    assert_in_delta Time.utc(2050, 1, 30, 12, 0), Event.last.date + 1.hour, 60
  end

  test 'a guide can create an event' do
    sign_in users(:guide_one)

    assert_difference('Event.count', 1) do
      post tour_events_path(@tour_guide_one, @valid_event_params_guide_one)
    end
    assert_redirected_to tour_url(@tour_guide_one)
  end

  test 'a guide can not create an event in the past' do
    sign_in users(:guide_one)

    assert_difference('Event.count', 0) do
      post tour_events_path(@tour_guide_one, {
                              event: {
                                tour_id: @tour_guide_one.id,
                                date: Time.now.round - 30.minutes
                              }
                            })
    end
    assert_response 422
  end

  test 'only the guide registered for the tour can create an event' do
    sign_in users(:guide_two)

    assert_difference('Event.count', 0) do
      post tour_events_path(@tour_guide_one, @valid_event_params_guide_one)
    end
    assert_response 403
  end

  test 'when there is no zoom license left' do
    # suppose that we have 2 licenses
    assert_equal 2, ZoomLicense.count

    # book 1st license
    e = Event.new(tour: @tour_guide_one, date: Time.now + 5.minutes)
    e.zoom_license_id = e.preferred_license_id
    e.save!

    # book 2nd license
    e = Event.new(tour: @tour_guide_two, date: Time.now + 5.minutes)
    e.zoom_license_id = e.preferred_license_id
    e.save!

    # a 3rd event at the same date must be refused
    sign_in users(:guide_three)
    assert_difference('Event.count', 0) do
      post tour_events_path(@tour_guide_three, @valid_event_params_guide_three)
    end
    assert_response 422
    assert_select '#error_explanation', /Zoom license can not be booked at the specified date/
  end

  test 'it is not possible for a guide to create two events at the same date' do
    # assign guide_one to an event now
    e = Event.new(tour: @tour_guide_one, date: Time.now + 20.minutes)
    e.zoom_license_id = e.preferred_license_id
    e.guide_id = @tour_guide_one.guide_id
    e.save!

    # assign guide_one to a second event now, this should fail
    assert_difference('Event.count', 0) do
      sign_in users(:guide_one)
      post tour_events_path(@tour_guide_one, @valid_event_params_guide_one)
    end

    assert_response 422
    assert_select '#error_explanation', /Date is already booked for this guide/
  end

  ############################
  #        DESTROY           #
  ############################
  test 'it requires the user to be authenticated to to delete an event' do
    assert_difference('Event.count', 0) do
      delete event_path(events(:event_three))
    end

    assert_redirected_to new_user_session_url
  end

  test 'an admin can delete an event' do
    sign_in users(:admin)

    event = events(:event_three)

    mock_mailer do |mailer|
      # a cancellation is sent to each globetrotter registered to the event
      EventRegistration.where(event: event).each do |er|
        mailer.expect(:with, mailer, [{ event_registration_id: er.id }])
        mailer.expect(:event_cancellation, mailer)
        mailer.expect(:deliver_later, nil)
      end
      # a cancellation is sent to the guide
      mailer.expect(:with, mailer, [{ event_id: event.id }])
      mailer.expect(:event_unscheduled, mailer)
      mailer.expect(:deliver_later, nil)

      assert_difference('Event.where(cancelled_date: nil).count', -1) do
        assert_difference('Event.where.not(cancelled_date: nil).count', 1) do
          delete event_path(event)
        end
      end
    end
    assert_redirected_to tour_url(@tour_guide_one)
  end

  test 'a guide can delete an event' do
    sign_in users(:guide_one)

    assert_difference('Event.where(cancelled_date: nil).count', -1) do
      assert_difference('Event.where.not(cancelled_date: nil).count', 1) do
        delete event_path(events(:event_three))
      end
    end
    assert_redirected_to tour_url(@tour_guide_one)
  end

  test 'only the guide registered for the tour can delete an event' do
    sign_in users(:guide_two)

    assert_difference('Event.count', 0) do
      delete event_path(events(:event_three))
    end
    assert_response 403, response.body
  end

  test 'a tour in the past can not be cancelled' do
    sign_in users(:guide_one)
    assert_difference('Event.count', 0) do
      delete event_path(events(:event_one))
    end
    assert_equal 'Event can not be cancelled because it already happened.', flash[:notice]
    assert_response 400
  end
end
