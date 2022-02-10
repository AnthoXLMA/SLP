# frozen_string_literal: true

require 'test_helper'

class ToursControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW next_events')
    @valid_tour_params = {
      tour: {
        guide_id: guides(:guide_one).id,
        country_id: countries(:country_one).id,
        title: 'TourTitle',
        subtitle: 'TourSubtitle',
        description: 'desc',
        short_description: 'short desc',
        duration: 'PT30M', # 30 minutes
        published: true
      }
    }
    @invalid_tour_params = {
      tour: {
        guide_id: 'invalid',
        title: ''
      }
    }
    @tour = tours(:tour_one)
  end

  ##############################
  #          INDEX             #
  ##############################
  test 'unauthenticated users are not allowed to get a list of all tours' do
    get tours_path
    assert_response 403
  end

  test 'guides can see their list of tours' do
    sign_in users(:guide_one)
    get tours_path
    assert_select '.ui.card > .content > .header > a',
                  Tour.joins(guide: :user).where('users.id' => users(:guide_one).id).count
  end

  test 'admin can see all tours' do
    sign_in users(:admin)
    get tours_path(all_guides: true)
    assert_select '.ui.card > .content > .header > a', Tour.count
  end

  test 'guides can not see all tours' do
    sign_in users(:guide_one)
    get tours_path(all_guides: true)
    assert_response 403
  end

  test 'it is possible to filter on all unpublished tours' do
    sign_in users(:admin)
    get tours_path(unpublished: true, all_guides: true)
    assert_select '.ui.card > .content > .header > a', tours(:unpublished_tour_one).title
  end

  ##############################
  #          EVENTS            #
  ##############################
  test 'it is available to unauthenticated users' do
    get events_tours_path
    assert_response :success
  end
  POSSIBLE_LANGUAGE_FILTERS = [['en'], ['fr'], %w[en fr]]
  test 'filter by language' do
    POSSIBLE_LANGUAGE_FILTERS.each do |lang|
      get events_tours_path,
          params: { filter_type: 'date', language: lang }
      expected_tours = Tour.published.where(language: lang).includes(:next_event).all.select(&:next_event)
      assert_select '.card', expected_tours.size
      expected_tours.each { |t| assert_select '.card > .content > .meta', t.subtitle }
    end
  end
  test 'by default, the language is filtered according to the preference of the user' do
    user = users(:user_one)
    sign_in user
    POSSIBLE_LANGUAGE_FILTERS.each do |lang|
      user.tour_language = lang
      user.save!
      get events_tours_path
      %w[en fr].each do |l|
        assert_select "#language_#{l}[checked=checked]", (lang.include?(l) ? 1 : 0)
      end
    end
  end
  test 'filter by hour' do
    tour = Tour.create!(@valid_tour_params[:tour].merge(subtitle: 'FilterByHourTitleSubtitle'))
    event = Event.create!(tour: tour, date: Time.utc(2200, 1, 1, 12, 0), zoom_license: zoom_licenses(:one))
    get events_tours_path,
        params: { filter_type: 'date', timeofday_begin: event.date.hour, timeofday_end: event.date.hour + 1, tz: 'UTC' }
    assert_response :success
    assert_select '.card > .content > .meta', tour.subtitle
  end
  test 'filter by hour with timezone' do
    tour = Tour.create!(@valid_tour_params[:tour].merge(subtitle: 'FilterByHourTitleSubtitleParisWinter'))
    event = Event.create!(tour: tour, date: Time.utc(2200, 1, 1, 12, 0), zoom_license: zoom_licenses(:one))
    get events_tours_path,
        params: { filter_type: 'date', timeofday_begin: event.date.hour + 1, timeofday_end: event.date.hour + 2,
                  tz: 'Paris' }
    assert_response :success
    assert_select '.card > .content > .meta', tour.subtitle
  end
  test 'filter by hour with timezone (Daylight Saving)' do
    tour = Tour.create!(@valid_tour_params[:tour].merge(subtitle: 'FilterByHourTitleSubtitleParisWinter'))
    event = Event.create!(tour: tour, date: Time.utc(2200, 8, 1, 12, 0), zoom_license: zoom_licenses(:one))
    get events_tours_path,
        params: { filter_type: 'date', timeofday_begin: event.date.hour + 2, timeofday_end: event.date.hour + 3,
                  tz: 'Paris' }
    assert_response :success
    assert_select '.card > .content > .meta', tour.subtitle
  end
  test 'filter by location' do
    get events_tours_path,
        params: { filter_type: 'location' }
    assert_response :success
    expected_tours = Tour.published.includes(:next_event).all.select(&:next_event)
    assert_select '.card', expected_tours.size
    expected_tours.each { |t| assert_select '.card > .content > .meta', t.subtitle }
  end
  test 'filter by location with specific country' do
    get events_tours_path,
        params: { filter_type: 'location', country: 'ES' }
    assert_response :success
    expected_tour = tours(:tour_two)
    assert_select '.card', 1
    assert_select '.card > .content > .meta', expected_tour.subtitle
  end
  test 'filter by location with specific region' do
    get events_tours_path,
        params: { filter_type: 'location', region: 'Europe' }
    assert_response :success
    assert_select '.card', 2
    assert_select '.card > .content > .meta', tours(:tour_one).subtitle
    assert_select '.card > .content > .meta', tours(:tour_one).subtitle
  end
  test 'unpublished tours should not be listed' do
    get events_tours_path
    assert_response :success
    assert_no_match(/#{tours(:unpublished_tour_one).subtitle}/, response.body)
  end
  ##############################
  #          SHOW              #
  ##############################
  test 'is available to unauthenticated users' do
    get tour_path(@tour)

    assert_response :success
  end

  test 'events are displayed ordered by date' do
    [4, 2, 1, 5].map do |d|
      Event.create!(tour: @tour, date: Time.now + d.days)
    end
    get tour_path(@tour)

    next_events_selector = '.registration.panel .right.floated.content input[name="event_registration[event_id]"]'
    b = Nokogiri::HTML(response.body)
    event_dates = b.css(next_events_selector).map { |n| Event.find(n['value']).date }

    assert_equal(5, event_dates.size)
    assert_equal event_dates.sort, event_dates, 'Array sorted'
  end

  test 'is available to guides' do
    sign_in users(:guide_one)
    get tour_path(@tour)

    assert_response :success
  end

  test 'is available to admins' do
    sign_in users(:admin)
    get tour_path(@tour)

    assert_response :success
  end

  test 'unpublished tours can be seen by admin' do
    sign_in users(:admin)
    get tour_path(tours(:unpublished_tour_one))

    assert_response :success
  end

  test 'unpublished tours can be seen by the guide who created the tour' do
    sign_in users(:guide_two)
    get tour_path(tours(:unpublished_tour_one))

    assert_response :success
  end

  test 'unpublished tours can not be seen by other guides' do
    sign_in users(:guide_one)
    get tour_path(tours(:unpublished_tour_one))

    assert_response 404
  end

  test 'unpublished tours can not be seen by regular users' do
    sign_in users(:user_one)
    get tour_path(tours(:unpublished_tour_one))

    assert_response 404
  end

  test 'unpublished tours can not be seen by unauthenticated users' do
    get tour_path(tours(:unpublished_tour_one))

    assert_response 404
  end

  ##############################
  #          NEW               #
  ##############################
  test 'it is required to be authenticated to get a form to create a tour' do
    get new_tour_path

    assert_redirected_to new_user_session_url
  end
  test 'it is possible for an admin to get a form to create a tour' do
    sign_in users(:admin)
    get new_tour_path

    assert_response :success
  end

  test 'it is possible for an admin to edit the name of the guide' do
    sign_in users(:admin)
    get new_tour_path

    assert_response :success
    %w[guide_one guide_two guide_three].each do |guide_firstname|
      assert_select '#tour_guide_id', /#{guide_firstname}/
    end
  end

  test 'it is possible for a guide to get a form to create a tour' do
    sign_in users(:guide_one)
    get new_tour_path

    assert_response :success
  end

  test 'it is not possible for a guide to edit the name of the guide' do
    sign_in users(:guide_one)
    get new_tour_path

    assert_response :success
    assert_select '#tour_user_id', 0
  end

  ##############################
  #          CREATE            #
  ##############################
  test 'it is required to be authenticated to create a tour' do
    assert_difference('Tour.count', 0) do
      post tours_path, params: @valid_tour_params
    end

    assert_redirected_to new_user_session_url
  end
  test 'it is possible for an admin to create a tour' do
    sign_in users(:admin)
    assert_difference('Tour.count', 1) do
      post tours_path, params: @valid_tour_params
    end

    assert_redirected_to tour_path(Tour.last)
  end
  test 'it is possible for a guide to create a tour' do
    sign_in users(:guide_one)
    assert_difference('Tour.count', 1) do
      post tours_path, params: @valid_tour_params
    end

    assert_redirected_to tour_path(Tour.last)
  end
  test 'if the params are invalid, an error is returned' do
    sign_in users(:admin)
    assert_difference('Tour.count', 0) do
      post tours_path, params: @invalid_tour_params
    end

    assert_select '#error_explanation', /Guide must exist/
    assert_response 422
  end
  test 'when a guide, guide_id is ignored' do
    guide = users(:guide_two)
    sign_in guide
    assert_difference('Tour.count', 1) do
      post tours_path, params: @valid_tour_params
    end
    assert_equal guide.guide.id, Tour.last.guide_id
  end
  test 'when an admin, guide_id is taken into account' do
    user = users(:admin)
    sign_in user
    assert_difference('Tour.count', 1) do
      post tours_path, params: @valid_tour_params
    end
    assert_equal @valid_tour_params[:tour][:guide_id], Tour.last.guide_id
  end
  ##############################
  #          EDIT              #
  ##############################
  test 'it is required to be authenticated to get a form to edit a tour' do
    get edit_tour_path(@tour)

    assert_redirected_to new_user_session_url
  end
  test 'it is not possible for a standard user to get a form to edit a tour' do
    sign_in users(:user_one)
    get edit_tour_path(@tour)

    assert_response 403
  end
  test 'it is possible for an admin to get a form to edit a tour' do
    sign_in users(:admin)
    get edit_tour_path(@tour)

    assert_response :success
  end
  test 'it is possible for a guide to get a form to edit a tour' do
    sign_in users(:guide_one)
    get edit_tour_path(@tour)

    assert_response :success
  end
  test "it is not possible for a guide to get a form to edit someone else's tour" do
    sign_in users(:guide_two)
    get edit_tour_path(@tour)

    assert_response 403
  end
  ##############################
  #         UPDATE             #
  ##############################
  test 'it is required to be authenticated to update a tour' do
    patch tour_path(@tour), params: @valid_tour_params

    assert_redirected_to new_user_session_url
  end
  test 'it is not possible for a standard user to update a tour' do
    sign_in users(:user_one)
    patch tour_path(@tour), params: @valid_tour_params

    assert_response 403
  end
  test 'it is possible for an admin to update a tour' do
    sign_in users(:admin)
    patch tour_path(@tour), params: @valid_tour_params
    @tour.reload

    assert_redirected_to tour_path(@tour)
  end
  test 'it is possible for a guide to update a tour' do
    sign_in users(:guide_one)
    patch tour_path(@tour), params: @valid_tour_params
    @tour.reload

    assert_redirected_to tour_path(@tour)
  end
  test 'if the update params are invalid, an error is returned' do
    sign_in users(:admin)
    patch tour_path(@tour), params: @invalid_tour_params
    @tour.reload

    assert_select '#error_explanation', /Title can't be blank/
    assert_response 422
  end
  test 'it is not possible to change the guide_id' do
    guide = users(:guide_two)
    sign_in guide
    previous_guide_id = @tour.guide.id
    patch tour_path(@tour), params: @valid_tour_params
    @tour.reload

    assert_equal previous_guide_id, @tour.guide_id
  end
  test "it is not possible for a guide to update someone else's tour" do
    user = users(:admin)
    sign_in user
    patch tour_path(@tour), params: @valid_tour_params
    @tour.reload

    assert_equal @valid_tour_params[:tour][:guide_id], @tour.guide_id
  end
  test "it returns a 404 if tour doesn't exist" do
    sign_in users(:admin)
    patch tour_path('bad_id')

    assert_response 404
  end
end
