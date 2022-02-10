# frozen_string_literal: true

require 'test_helper'

class GuideEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  ##############################
  #          INDEX             #
  ##############################
  test 'it is required to be authenticated to list all events for a guide' do
    get guide_events_path

    assert_redirected_to new_user_session_url
  end

  test 'an admin can view all events for all guides' do
    sign_in users(:admin)
    get guide_events_path(show_all: true)

    assert_response 200
    assert_select '.guide_event', 4
  end

  test 'an admin can view its own events' do
    sign_in users(:admin)
    get guide_events_path

    assert_response 200
    assert_select '.guide_event', 0
  end

  test 'a guide can view its own events' do
    sign_in users(:guide_one)
    get guide_events_path

    assert_response 200
    assert_select '.guide_event', 2
  end
end
