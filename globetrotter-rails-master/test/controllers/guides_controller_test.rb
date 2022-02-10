# frozen_string_literal: true

require 'test_helper'

class GuidesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @valid_guide_params = {
      guide: {
        guide_id: guides(:guide_one).id,
        description: 'description',
        short_description: 'short_description',
        location: 'location'
      }
    }
    @invalid_guide_params = {
      guide: {
        guide_id: 'invalid',
        description: ''
      }
    }
    @valid_create_params = {
      guide: {
        user_id: users(:user_one).id,
        description: 'desc',
        short_description: 'short_desc',
        location: 'loc'
      }
    }
    @guide = guides(:guide_one)
  end

  ##############################
  #          SHOW              #
  ##############################
  test 'it is possible to view a guide' do
    get guide_path(@guide.id)

    assert_response 200
  end

  test 'it is possible to view a guide when logged as this guide' do
    guide = users(:guide_one)
    sign_in guide
    get guide_path(guide.id)

    assert_response 200
  end

  test 'it is possible to view a guide when logged as admin' do
    sign_in users(:admin)
    get guide_path(@guide.id)

    assert_response 200
  end

  test 'events are displayed ordered by date' do
    [4, 2, 1, 5].map do |d|
      Event.create!(tour: @guide.tours.first, date: Time.now + d.days)
    end
    get guide_path(@guide.id)

    next_events_selector = '.registration.panel .right.floated.content input[name="event_registration[event_id]"]'
    b = Nokogiri::HTML(response.body)
    event_dates = b.css(next_events_selector).map { |n| Event.find(n['value']).date }

    assert_equal(5, event_dates.size)
    assert_equal event_dates.sort, event_dates, 'Array sorted'
  end

  test 'events related to unpublished events are not shown' do
    tour = @guide.tours.first
    [4, 2, 1, 5].map do |d|
      Event.create!(tour: tour, date: Time.now + d.days)
    end
    tour.published = false
    tour.save!
    get guide_path(@guide.id)

    next_events_selector = '.registration.panel .right.floated.content input[name="event_registration[event_id]"]'
    b = Nokogiri::HTML(response.body)
    event_dates = b.css(next_events_selector).map { |n| Event.find(n['value']).date }

    assert_equal(0, event_dates.size)
  end

  test 'it is not possible to view a guide which is not yet published' do
    guide = guides(:guide_one)
    guide.published = false
    guide.save!

    get guide_path(guide.id)

    assert_response :not_found
  end

  ##############################
  #          EDIT              #
  ##############################
  test 'it is required to be authenticated to get a form to edit a guide' do
    get edit_guide_path(@guide)

    assert_redirected_to new_user_session_url
  end
  test 'it is not possible for a standard user to get a form to edit a guide' do
    sign_in users(:user_one)
    get edit_guide_path(@guide)

    assert_response 403
  end
  test 'it is possible for an admin to get a form to edit a guide' do
    sign_in users(:admin)
    get edit_guide_path(@guide)

    assert_response :success
  end
  test 'it is possible for a guide to get a form to edit a guide' do
    sign_in users(:guide_one)
    get edit_guide_path(@guide)

    assert_response :success
  end
  test "it is not possible for a guide to get a form to edit someone else's guide" do
    sign_in users(:guide_two)
    get edit_guide_path(@guide)

    assert_response 403
  end
  ##############################
  #         UPDATE             #
  ##############################
  test 'it is required to be authenticated to update a guide' do
    patch guide_path(@guide), params: @valid_guide_params

    assert_redirected_to new_user_session_url
  end
  test 'it is not possible for a standard user to update a guide' do
    sign_in users(:user_one)
    patch guide_path(@guide), params: @valid_guide_params

    assert_response 403
  end
  test 'it is possible for an admin to update a guide' do
    sign_in users(:admin)
    patch guide_path(@guide), params: @valid_guide_params
    @guide.reload

    assert_redirected_to guide_path(@guide)
  end
  test 'it is possible for a guide to update a guide' do
    sign_in users(:guide_one)
    patch guide_path(@guide), params: @valid_guide_params
    @guide.reload

    assert_equal 'description', @guide.description
    assert_equal 'short_description', @guide.short_description
    assert_equal 'location', @guide.location

    assert_redirected_to guide_path(@guide)
  end
  test 'if the update params are invalid, an error is returned' do
    sign_in users(:admin)
    patch guide_path(@guide), params: @invalid_guide_params
    @guide.reload

    assert_response 422
    assert_select '#error_explanation', /Description can't be blank/
  end
  test 'it is not possible to change the guide_id' do
    guide = users(:guide_two)
    sign_in guide
    previous_guide_id = @guide.id
    patch guide_path(@guide), params: @valid_guide_params
    @guide.reload

    assert_equal previous_guide_id, @guide.id
  end
  test "it is not possible for a guide to update someone else's guide" do
    user = users(:admin)
    sign_in user
    patch guide_path(@guide), params: @valid_guide_params
    @guide.reload

    assert_equal @valid_guide_params[:guide][:guide_id], @guide.id
  end
  test "it returns a 404 if guide doesn't exist" do
    sign_in users(:admin)
    patch guide_path('bad_id')

    assert_response 404
  end

  ##############################
  #          DELETE            #
  ##############################
  test 'it is not possible to delete a guide when not logged in' do
    delete guide_path(@guide.id)

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to delete a guide when logged as a normal user' do
    sign_in users(:user_one)
    delete guide_path(@guide.id)

    assert_response 403
  end

  test 'it is possible to delete a guide when logged as an admin' do
    sign_in users(:admin)

    assert_difference('Guide.published.count', -1) do
      delete guide_path(@guide.id)
    end

    assert_redirected_to guides_path
  end

  ##############################
  #            NEW             #
  ##############################
  test 'it is not possible to get a form to create a guide when not logged in' do
    get guides_path

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to get a form to create a guide when logged as admin' do
    sign_in users(:admin)
    get guides_path

    assert_response 200
  end

  ##############################
  #          CREATE            #
  ##############################
  test 'it is not possible to create a guide when not logged in' do
    assert_difference('Guide.count', 0) do
      post guides_path, params: @valid_create_params
    end

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to create a guide' do
    sign_in users(:admin)
    assert_difference('Guide.count', 1) do
      post guides_path, params: @valid_create_params
    end

    created_guide = users(:user_one).guide
    assert_redirected_to guide_path(created_guide.id)
    # by default, this guide should be 'unpublished'
    assert !created_guide.published
  end
end
