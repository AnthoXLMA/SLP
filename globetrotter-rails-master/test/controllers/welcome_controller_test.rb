# frozen_string_literal: true

require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  ##############################
  #          INDEX             #
  ##############################
  test 'it is possible to view the page without being authenticated' do
    get welcome_url
    assert_response :success
  end

  test 'unpublished tours are not listed' do
    get welcome_url, params: { tz: 'Europe/Paris' }
    assert_response :success
    assert_no_match(/#{tours(:unpublished_tour_one).subtitle}/, response.body)
  end

  test 'unpublished guides are not listed' do
    tour = tours(:tour_one)
    get welcome_url, params: { tz: 'Europe/Paris' }
    assert_response :success
    assert_match(/#{tour.subtitle}/, response.body)

    tour.guide.published = false
    tour.guide.save!
    get welcome_url, params: { tz: 'Europe/Paris' }
    assert_response :success
    assert_no_match(/#{tour.subtitle}/, response.body)
  end

  test 'when authenticated, the page contains a usermenu' do
    user = users(:user_one)
    sign_in user
    get welcome_url

    assert_select '.usermenu > .button', user.email
  end

  test 'when no timezone is configured, a timezone detection happens' do
    get welcome_url
    assert_select '#force_reload_timezone', /Detecting timezone/
    assert_nil cookies['tz']
  end

  test 'it is possible to specify the timezone' do
    get welcome_url, params: { tz: 'Europe/Paris' }
    assert_select '#force_reload_timezone', { count: 0 }
    assert_equal 'Europe/Paris', cookies['tz']

    # tz is stored in a cookie, it is not necessary for the next views
    get welcome_url
    assert_select '#force_reload_timezone', { count: 0 }
    assert_equal 'Europe/Paris', cookies['tz']
  end

  test 'it is possible to specify the language' do
    get welcome_url(locale: 'en')
    assert_select '#force_reload_timezone', /Detecting timezone/
    assert_equal 'en', cookies['locale']

    get welcome_url(locale: 'fr')
    assert_select '#force_reload_timezone', /Détection du fuseau horaire/
    assert_equal 'fr', cookies['locale']

    # locale is stored in the cookie is not necessary for the next views
    get welcome_url(locale: nil)
    assert_select '#force_reload_timezone', /Détection du fuseau horaire/
    assert_equal 'fr', cookies['locale']
  end

  test 'if the user has configured a timezone/language, that timezone/language is used' do
    user = users(:user_one)
    sign_in user
    get welcome_url(locale: nil)
    assert_equal 'Pacific/Pago_Pago', cookies['tz']
    assert_equal 'fr', cookies['locale']
    assert_select '.ui.huge.button.primary.board', /Choisir une visite/
  end

  test 'if the user is registered to an event which is happening now, display a popup' do
    # user_one has no live event
    user = users(:user_one)
    sign_in user
    get welcome_url

    assert_select '#live_event_modal', 0

    # user_two has a live event
    user = users(:user_two)
    sign_in user
    get welcome_url

    assert_select '#live_event_modal', 1

    # once user two has exited from the event: do not display the message
    get after_event_event_registration_path(event_registrations(:event_registration_two))
    assert_select '#live_event_modal', 0
    get welcome_url
    assert_select '#live_event_modal', 0
  end

  test 'if a guide has scheduled an event which is happening now, display a popup to this guide' do
    # guide_one has no live event
    guide = users(:guide_one)
    sign_in guide
    get welcome_url
    assert_select '#live_event_modal', 0

    # create an event for guide_one now
    e = Event.new(date: Time.now + 5.minutes, tour: tours(:tour_one), zoom_meeting_details: {})
    e.save!
    get welcome_url
    assert_select '#live_event_modal', 1

    # no modal is displayed if the guide is starting the event
    Zoom::API.connection.expect(:get, Zoom.test_response('{"email": "testemail@gt.live"}', success: true),
                                ['/v2/users/zoom_user_id1', nil])
    get guide_event_path(e)
    assert_select '#live_event_modal', 0
  end

  test 'a cookie banner is displayed' do
    # when not logged in, the banner is displayed
    get welcome_url
    assert_select '#cookie_banner', 1

    # when cookies are disabled
    get welcome_url, params: { accept_google_analytics: false }
    # cookies are enabled/disabled for the whole session
    get welcome_url
    # the banner is not displayed
    assert_select '#cookie_banner', 0
    # google is not loaded
    assert_select '#google-analytics-script', 0

    # when cookies are enabled
    get welcome_url, params: { accept_google_analytics: true }
    # cookies are enabled/disabled for the whole session
    get welcome_url
    # the banner is not displayed
    assert_select '#cookie_banner', 0
    # google is not loaded
    assert_select '#google-analytics-script', 1
  end

  test 'cookie banner: the preferences from the user are used' do
    # when a user is logged in, the preferences from the user are used
    user = users(:user_one)
    sign_in user

    user.accept_google_analytics = nil
    user.save!
    get welcome_url
    assert_select '#cookie_banner', 1

    user.accept_google_analytics = :false
    user.save!
    get welcome_url
    assert_select '#cookie_banner', 0
    assert_select '#google-analytics-script', 0

    user.accept_google_analytics = :true
    user.save!
    get welcome_url
    assert_select '#cookie_banner', 0
    assert_select '#google-analytics-script', 1
  end

  POSSIBLE_LANGUAGE_FILTERS = [['en'], ['fr'], %w[en fr]]
  test 'only tours in the language of the user must be displayed' do
    user = users(:user_one)
    sign_in user
    POSSIBLE_LANGUAGE_FILTERS.each do |lang|
      user.tour_language = lang
      user.save!
      get welcome_url

      # all tours shown on the page should be suggested tours
      suggested_tours = Tour.suggested(user)
      selected_nodes = assert_select '.card > .content > .header > a',
                                     [Tour::DEFAULT_SUGGESTED_COUNT, suggested_tours.size].min
      suggested_tours_path = suggested_tours.map { |t| tour_path(t) }
      selected_nodes.each do |n|
        assert(suggested_tours_path.include?(n.attr('href')))
      end
    end
  end
end
